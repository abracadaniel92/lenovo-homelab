#!/bin/bash
###############################################################################
# Standalone HDD SMART health check (USB docking stations)
# Run daily via systemd; sends Mattermost report only on Sunday 11:00.
# Requires: smartmontools, health.d/40-disk-smart.sh, health_webhook_url
#
# Status: ACTIVE — production HDD SMART check. Wired up via
# systemd/hdd-health-check.timer. Deployed via scripts/deploy-hdd-health-check.sh.
###############################################################################

LOG_FILE="/var/log/hdd-health-check.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" 2>/dev/null || echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

send_slack_notification() {
    local title="$1"
    local message="$2"
    local icon="${3:-🚨}"
    WEBHOOK_URL=$(cat "$SCRIPT_DIR/health_webhook_url" 2>/dev/null || echo "")
    if [ -z "$WEBHOOK_URL" ]; then
        log "WARNING: health_webhook_url not found in $SCRIPT_DIR"
        return
    fi
    local payload="{\"text\": \"$icon **$title**\n$message\"}"
    curl -s -X POST -H 'Content-Type: application/json' --data "$payload" "$WEBHOOK_URL" > /dev/null
}

MODULE="$SCRIPT_DIR/health.d/40-disk-smart.sh"
if [ ! -f "$MODULE" ]; then
    log "ERROR: Disk module not found: $MODULE"
    exit 1
fi

source "$MODULE"
