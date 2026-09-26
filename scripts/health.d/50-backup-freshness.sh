#!/bin/bash
# 50-backup-freshness.sh: alert when a service's newest backup is stale or absent.
#
# Sourced by health-check-engine.sh, so log() and send_slack_notification() come
# from there and SCRIPT_DIR is scripts/.
#
# Why this exists: backups ran off bare cron with no monitoring, the cron entry
# broke on an unquoted path in 2026-01, and nobody noticed for eight months
# (troubleshooting-log 2026-09-25). This is deliberately outcome-based rather
# than checking whether the timer fired, so it catches every cause at once:
# broken cron, crashed engine, full disk, container that will not stop.
#
# ponytail: compares mtime of the newest matching archive, nothing more. It does
# NOT validate archive contents, which would mean extracting every backup every
# hour. Ceiling: a backup that runs on schedule but writes garbage still reads as
# fresh. Upgrade path: have backup-engine.sh drop a .ok sidecar after a
# post-backup row-count check and assert on that sidecar here instead.

BACKUP_CONF_DIR="$SCRIPT_DIR/backup.d"
DEFAULT_MAX_AGE_HOURS=48

if [ ! -d "$BACKUP_CONF_DIR" ]; then
    log "WARNING: backup config dir not found: $BACKUP_CONF_DIR"
    # Sourced by the engine, but runnable standalone by the self-check, so bail
    # whichever way we were invoked.
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

backup_problems=""

for conf in "$BACKUP_CONF_DIR"/*.conf; do
    [ -f "$conf" ] || continue

    # Subshell: backup.d confs set SERVICE_NAME/DST_DIR/TYPE/... and this module
    # is source'd into the engine, so without isolation those would leak into the
    # engine and into whatever module it sources next.
    problem=$(
        # shellcheck source=/dev/null
        . "$conf" 2>/dev/null || exit 0
        [ -n "$DST_DIR" ] && [ -n "$FILENAME_PREFIX" ] || exit 0

        max_age=${MAX_AGE_HOURS:-$DEFAULT_MAX_AGE_HOURS}
        # shellcheck disable=SC2012  # names are engine-generated timestamps, no newlines or globs
        newest=$(ls -t "$DST_DIR/${FILENAME_PREFIX}"-*."${EXTENSION}" 2>/dev/null | head -1)

        if [ -z "$newest" ]; then
            echo "• ${SERVICE_NAME:-$FILENAME_PREFIX}: NO backup found in $DST_DIR"
            exit 0
        fi

        age_h=$(( ( $(date +%s) - $(stat -c %Y "$newest") ) / 3600 ))
        if [ "$age_h" -gt "$max_age" ]; then
            echo "• ${SERVICE_NAME:-$FILENAME_PREFIX}: newest backup is ${age_h}h old (limit ${max_age}h) — $(basename "$newest")"
        elif [ ! -f "$newest.ok" ]; then
            # backup-engine.sh writes the sidecar only after the archive passes
            # a real read (tar -tzf, or PRAGMA integrity_check for SQLite). Its
            # absence means the backup either failed verification or was written
            # by a version that did not verify. Fresh-but-unverified is the gap
            # this module used to have: mtime alone cannot tell a good archive
            # from a corrupt one written on schedule.
            echo "• ${SERVICE_NAME:-$FILENAME_PREFIX}: newest backup is UNVERIFIED (no .ok sidecar): $(basename "$newest")"
        fi
    )

    [ -n "$problem" ] && backup_problems="${backup_problems}${problem}"$'\n'
done

if [ -n "$backup_problems" ]; then
    log "CRITICAL: stale or missing backups detected:"
    log "$backup_problems"
    send_slack_notification "🚨 Backups stale or missing" "$backup_problems" "🚨"
else
    log "Backup freshness: all services within their max age"
fi
