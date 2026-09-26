#!/bin/bash
# 60-offsite-freshness.sh: alert when a service's newest OFFSITE (B2) copy is
# stale or absent, or when B2 cannot be listed at all.
#
# Sourced by health-check-engine.sh, so log() and send_slack_notification() come
# from there and SCRIPT_DIR is scripts/.
#
# Why this exists: until 2026-09-26 nothing looked at B2. The sync ran off bare
# cron, so the offsite copy could stop updating while every signal read green
# (troubleshooting-log 2026-09-26). Outcome-based like 50-backup-freshness.sh:
# it checks what is actually in the bucket, not whether the timer fired.
#
# One recursive listing per run, not one per service: B2 list calls are class B
# transactions, and this runs hourly.
#
# ponytail: trusts rclone's stored ModTime (the local archive's mtime), does not
# download anything. Ceiling: an upload that lands but is corrupt reads fresh.
# The md5 check in setup-b2-encrypted-sync.sh covers that once; upgrade path is
# a weekly `rclone check --download` of the newest archive per service.

BACKUP_CONF_DIR="$SCRIPT_DIR/backup.d"
OFFSITE_REMOTE="${OFFSITE_REMOTE:-b2-crypt:current}"
RCLONE_CONF="${RCLONE_CONF:-/home/goce/.config/rclone/rclone.conf}"
DEFAULT_MAX_AGE_HOURS=48
# The offsite copy is behind the local one by design: the 02:00 backup is
# uploaded at 03:00, and a missed run is retried by the next day's timer.
OFFSITE_GRACE_HOURS=24

# Stay quiet until setup-b2-encrypted-sync.sh has run; before that the crypt
# remote does not exist and this would alarm every hour for a known state.
if ! systemctl is-enabled --quiet sync-backups-to-b2.timer 2>/dev/null; then
    log "Offsite freshness: skipped, sync-backups-to-b2.timer not enabled (run scripts/setup-b2-encrypted-sync.sh)"
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

# Runs as root; the rclone config belongs to goce.
if ! offsite_listing=$(rclone --config "$RCLONE_CONF" lsf -R --files-only \
        --format tp --separator '|' --time-format unix "$OFFSITE_REMOTE" 2>&1); then
    log "CRITICAL: cannot list offsite backups at $OFFSITE_REMOTE"
    send_slack_notification "🚨 Offsite backups unreadable" "rclone could not list $OFFSITE_REMOTE:"$'\n'"$(tail -3 <<<"$offsite_listing")" "🚨"
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

offsite_problems=""
for conf in "$BACKUP_CONF_DIR"/*.conf; do
    [ -f "$conf" ] || continue
    # Subshell: confs set SERVICE_NAME/DST_DIR/... and must not leak into the engine.
    problem=$(
        # shellcheck source=/dev/null
        . "$conf" 2>/dev/null || exit 0
        [ -n "$FILENAME_PREFIX" ] || exit 0
        max_age=$(( ${MAX_AGE_HOURS:-$DEFAULT_MAX_AGE_HOURS} + OFFSITE_GRACE_HOURS ))
        name="${SERVICE_NAME:-$FILENAME_PREFIX}"

        # Lines are "unixtime|dir/file". Match on the file name only.
        newest=$(awk -F'|' -v p="${FILENAME_PREFIX}-" -v e=".${EXTENSION}" '
            { n = split($2, a, "/"); f = a[n] }
            index(f, p) == 1 && substr(f, length(f) - length(e) + 1) == e && $1 > max { max = $1 }
            END { print max + 0 }' <<<"$offsite_listing")

        if [ "$newest" -eq 0 ]; then
            echo "• $name: NO offsite copy in $OFFSITE_REMOTE"
        else
            age_h=$(( ( $(date +%s) - newest ) / 3600 ))
            [ "$age_h" -gt "$max_age" ] && echo "• $name: newest offsite copy is ${age_h}h old (limit ${max_age}h)"
        fi
    )
    [ -n "$problem" ] && offsite_problems="${offsite_problems}${problem}"$'\n'
done

if [ -n "$offsite_problems" ]; then
    log "CRITICAL: stale or missing offsite backups:"
    log "$offsite_problems"
    send_slack_notification "🚨 Offsite backups stale or missing" "$offsite_problems" "🚨"
else
    log "Offsite freshness: all services within their max age"
fi
