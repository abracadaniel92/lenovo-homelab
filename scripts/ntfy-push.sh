#!/bin/bash
# Phone push for critical alerts: ntfy-push.sh "<title>"
# Called by health-check-engine.sh (🚨 alerts only) and notify-unit-failure.sh.
# Mattermost still gets the full alert; this is the "look at Mattermost" nudge.
#
# Sends the TITLE only. The topic lives on public ntfy.sh, where anyone who
# knows the topic name can read it, and alert bodies carry paths and log lines.
#
# Topic URL comes from scripts/ntfy_topic_url (gitignored, like
# health_webhook_url), e.g. https://ntfy.sh/<topic>. No file = no push.
#
# ponytail: dedup is one stamp file per title in tmpfs, 6h window. The health
# engine has no alert throttling and re-alerts every hourly run, which would
# otherwise mean 24 pushes a day for one stale backup, and a muted topic.
# Ceiling: stamps reset on reboot, and a title with a changing number in it
# would never dedup (none of the current 🚨 titles have one).
set -uo pipefail

TITLE="${1:?usage: ntfy-push.sh <title>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOPIC_FILE="${NTFY_TOPIC_FILE:-$SCRIPT_DIR/ntfy_topic_url}"
STATE_DIR="${NTFY_STATE_DIR:-/run/homelab-ntfy}"
DEDUP_MINUTES="${NTFY_DEDUP_MINUTES:-360}"

TOPIC_URL=$(cat "$TOPIC_FILE" 2>/dev/null) || exit 0
[ -n "$TOPIC_URL" ] || exit 0

mkdir -p "$STATE_DIR"
stamp="$STATE_DIR/$(md5sum <<<"$TITLE" | cut -c1-16)"
if [ -n "$(find "$stamp" -mmin "-$DEDUP_MINUTES" 2>/dev/null)" ]; then
    exit 0
fi

if curl -fsS --max-time 10 -H "Title: lemongrab" -H "Priority: ${NTFY_PRIORITY:-high}" -d "$TITLE" "$TOPIC_URL" >/dev/null; then
    touch "$stamp"
else
    echo "ntfy-push: POST to ntfy failed for: $TITLE" >&2
    exit 1
fi
