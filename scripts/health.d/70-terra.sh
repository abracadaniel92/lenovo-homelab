#!/bin/bash
# 70-terra.sh: alert when the newest restic snapshot on the Terra is older than
# 48 h, or the Terra repo cannot be read at all (terra/README.md Part B step 6).
#
# Sourced by health-check-engine.sh, so log() and send_slack_notification() come
# from there. Outcome-based like 50/60: it asks the repo what it holds instead of
# trusting that backup-immich-terra.timer fired (timers that silently stopped
# cost eight months of backups, troubleshooting-log 2026-09-25).
#
# ponytail: reads snapshot metadata only (--no-lock, no data). Ceiling: a
# snapshot that lands but has bad blobs reads fresh. Upgrade path: a weekly
# `restic check --read-data-subset=5%` unit.

TERRA_MAX_AGE_HOURS=48

# Stay quiet until scripts/setup-terra-backup.sh has run.
if ! systemctl is-enabled --quiet backup-immich-terra.timer 2>/dev/null; then
    log "Terra offsite: skipped, backup-immich-terra.timer not enabled (run scripts/setup-terra-backup.sh)"
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

if ! terra_json=$(RESTIC_PASSWORD_FILE=/root/.config/restic/terra.pass \
        RESTIC_REPOSITORY_FILE=/root/.config/restic/terra.repo \
        timeout 120 restic snapshots --no-lock --latest 1 --json 2>&1); then
    log "CRITICAL: cannot read the Terra restic repo"
    send_slack_notification "🚨 Terra offsite repo unreachable" "restic snapshots failed:"$'\n'"$(tail -3 <<<"$terra_json")" "🚨"
    # shellcheck disable=SC2317
    return 0 2>/dev/null || exit 0
fi

# restic prints RFC 3339 with nanoseconds; Python 3.11+ fromisoformat parses it after trimming to micro.
terra_age_h=$(python3 -c '
import json, sys, re, datetime as d
s = json.loads(sys.argv[1])
if not s: print(-1); sys.exit()
t = re.sub(r"(\.\d{6})\d*", r"\1", max(x["time"] for x in s))
print(int((d.datetime.now(d.timezone.utc) - d.datetime.fromisoformat(t)).total_seconds() // 3600))
' "$terra_json" 2>/dev/null || echo -2)

if [ "$terra_age_h" -lt 0 ]; then
    log "CRITICAL: no readable snapshot in the Terra repo"
    send_slack_notification "🚨 Terra offsite: no snapshot" "restic returned no snapshot (or unparseable output)." "🚨"
elif [ "$terra_age_h" -gt "$TERRA_MAX_AGE_HOURS" ]; then
    log "CRITICAL: newest Terra snapshot is ${terra_age_h}h old (limit ${TERRA_MAX_AGE_HOURS}h)"
    send_slack_notification "🚨 Terra offsite backup stale" "Newest snapshot is ${terra_age_h}h old (limit ${TERRA_MAX_AGE_HOURS}h)." "🚨"
else
    log "Terra offsite: newest snapshot ${terra_age_h}h old"
fi
