#!/bin/bash
###############################################################################
# Modular Health Check Engine
# Dynamically executes check modules from health.d/
#
# Status: PRODUCTION. enhanced-health-check.timer runs THIS script hourly, via
# /opt/homelab (drop-in: /etc/systemd/system/enhanced-health-check.service.d/).
#
# ⚠️ The migration off enhanced-health-check.sh is INCOMPLETE, and that script
# is still what `make health` runs. Not yet ported, so NOT covered hourly:
#   - check_caddyfile_integrity  (the gzip / mobile-download guard, 2026-01-08)
#   - check_udp_buffers
#   - the docker-daemon running check
#   - HTTP checks for Jellyfin, Nextcloud, Linkwarden
#   - the 80% disk warning tier (below only alerts at >90%) and the per-hour
#     alert throttling, so a sustained problem re-notifies every run
# A green run here is therefore not equivalent to `make health`.
###############################################################################

LOG_FILE="/var/log/enhanced-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/health.d"

# Rotate log
if [ -f "$LOG_FILE" ] && [ "$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)" -gt "$MAX_LOG_SIZE" ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Mattermost notification function
send_slack_notification() {
    local title="$1"
    local message="$2"
    local icon="${3:-🚨}"

    # Get webhook from environment or file
    WEBHOOK_URL=$(cat "$SCRIPT_DIR/health_webhook_url" 2>/dev/null || echo "")
    if [ -z "$WEBHOOK_URL" ]; then
        log "WARNING: Notification webhook URL not found in $SCRIPT_DIR/health_webhook_url"
        return
    fi

    local payload="{\"text\": \"$icon **$title**\n$message\"}"
    curl -s -X POST -H 'Content-Type: application/json' --data "$payload" "$WEBHOOK_URL" > /dev/null
}

check_service_http() {
    local url=$1
    local timeout=${2:-5}
    curl -s --connect-timeout "$timeout" "$url" > /dev/null
    return $?
}

check_external_access() {
    local domain=$1
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$domain")
    if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 301 ] || [ "$status_code" -eq 302 ]; then
        return 0
    else
        return 1
    fi
}

# Guards the invariant in CLAUDE.md: tunnel service: URLs must be
# http://localhost:8080, never 127.0.0.1:8080, which fails intermittently here.
#
# This was previously a no-op that grep'd /etc/caddy/config.d/*.caddy, a path
# that does not exist on the host (Caddy's configs live in the container and in
# the repo), so the glob never matched, nothing was ever logged, and the guard
# reported healthy by doing nothing. Same failure shape as the 2026-01-28
# outage: a check that cannot fail is not a check.
#
# Detect-and-alert rather than the old script's silent `sed -i` auto-fix:
# ~/.cloudflared/config.yml is append-only/sacred, and an in-place edit does not
# take effect until cloudflared restarts, so the quiet fix left the running
# tunnel broken while looking resolved.
check_config_integrity() {
    local cf_config="/home/goce/.cloudflared/config.yml"
    if [ ! -f "$cf_config" ]; then
        log "ERROR: cloudflared config not found at $cf_config"
        send_slack_notification "🚨 cloudflared config missing" "Expected at $cf_config" "🚨"
        return 1
    fi
    if grep -q "127\.0\.0\.1:8080" "$cf_config"; then
        log "WARNING: 127.0.0.1:8080 in $cf_config, must be localhost:8080"
        send_slack_notification "⚠️ Tunnel config regression" \
            "\`$cf_config\` contains \`127.0.0.1:8080\`, which fails intermittently on this host. Replace with \`localhost:8080\` and restart cloudflared." "⚠️"
    else
        # Logged even when healthy, on purpose. A check that is silent when it
        # passes is indistinguishable in the log from a check that never ran,
        # and that ambiguity is what hid the 2026-01-28 outage for 8 months.
        log "Tunnel config OK: no 127.0.0.1:8080 in $cf_config"
    fi
}

check_memory_usage() {
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 90.0" | bc -l) )); then
        log "CRITICAL: Memory usage at ${mem_usage}%"
        send_slack_notification "🚨 CRITICAL: High Memory Usage" "System memory usage is at ${mem_usage}%." "🚨"
    fi
}

check_disk_space() {
    local path=$1
    local label=$2
    local usage
    usage=$(df -h "$path" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$usage" -gt 90 ]; then
        log "CRITICAL: Disk space on $label ($path) is at ${usage}%"
        send_slack_notification "🚨 CRITICAL: Low Disk Space" "Disk space on $label ($path) is at ${usage}%." "🚨"
    fi
}

# Start Health Check
log "Starting modular health check run..."

# Global Checks
check_config_integrity
check_memory_usage
check_disk_space "/" "Root"
check_disk_space "/mnt/ssd" "SSD"

# Execute Modules from health.d
if [ -d "$MODULES_DIR" ]; then
    for module in "$MODULES_DIR"/*.sh; do
        if [ -x "$module" ]; then
            log "Executing module: $(basename "$module")"
            # shellcheck source=/dev/null
            source "$module"
        else
            log "Skipping non-executable module: $(basename "$module")"
        fi
    done
else
    log "ERROR: Modules directory not found: $MODULES_DIR"
fi

log "Modular health check run complete"
