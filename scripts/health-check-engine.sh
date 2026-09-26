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

    # Criticals also go to the phone (title only, deduped). Before the webhook
    # check, so a missing Mattermost webhook does not silence the push too.
    if [ "$icon" = "🚨" ]; then
        "$SCRIPT_DIR/ntfy-push.sh" "$title" 2>&1 | while read -r l; do log "ERROR: $l"; done
    fi

    # Get webhook from environment or file
    WEBHOOK_URL=$(cat "$SCRIPT_DIR/health_webhook_url" 2>/dev/null || echo "")
    if [ -z "$WEBHOOK_URL" ]; then
        log "WARNING: Notification webhook URL not found in $SCRIPT_DIR/health_webhook_url"
        return
    fi

    # JSON via python rather than string interpolation: alert bodies carry file
    # paths, log excerpts and backticks, and a single quote or backslash would
    # produce invalid JSON that Mattermost rejects. notify-unit-failure.sh takes
    # the same approach for the same reason.
    local payload
    payload=$(python3 -c 'import json,sys; print(json.dumps({"text": f"{sys.argv[1]} **{sys.argv[2]}**\n{sys.argv[3]}"}))' \
        "$icon" "$title" "$message" 2>/dev/null)
    if [ -z "$payload" ]; then
        log "ERROR: could not encode notification payload for: $title"
        return 1
    fi

    # The delivery result was previously discarded, so a rotated webhook or a
    # Mattermost outage silenced every alert with no trace in the log. An
    # alerting path that cannot report its own failure is the bug this whole
    # system was built to stop having.
    local response http_code
    response=$(curl -s -w '\n%{http_code}' --max-time 15 -X POST \
        -H 'Content-Type: application/json' --data "$payload" "$WEBHOOK_URL" 2>&1)
    http_code=$(printf '%s' "$response" | tail -1)
    if [ "$http_code" != "200" ]; then
        log "ERROR: notification FAILED to send (HTTP ${http_code:-none}): $title"
        return 1
    fi
}

# Treats any 2xx/3xx as up. The previous version was `curl -s ... ; return $?`,
# which exits 0 for ANY response that arrives, so 404/500/502/503 all read as
# healthy and only a refused connection registered. Caddy's documented failure
# mode here is serving 502s (troubleshooting-log 2026-01-04, 01-06, 01-08), so
# the Caddy auto-restart could never fire for the outage it exists to fix.
#
# --max-time, not just --connect-timeout: a service that accepts the connection
# and never answers made curl wait forever, and the unit has no start timeout,
# so the whole health check hung. A hang is not a failure, so OnFailure= stays
# quiet: exactly the shape of the 8-month silent outage.
#
# ponytail: 4xx counts as down. Ceiling: a service that answers 401/403 by
# design would read as down and get restarted hourly. None of the current call
# sites do (all verified answering 200 or 302). Add the code to the accept list
# here if one ever does.
check_service_http() {
    local url=$1
    local timeout=${2:-5}
    local status
    status=$(curl -s -o /dev/null -w '%{http_code}' --max-time "$timeout" "$url" 2>/dev/null)
    case "$status" in
        2??|3??) return 0 ;;
        *)       return 1 ;;
    esac
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

# Docker must be up before any module runs: nearly every one of them shells out
# to docker, and without this they each fail separately with confusing output
# instead of one clear cause. Carried over from enhanced-health-check.sh, which
# had it and the modular rewrite dropped.
#
# Bounded wait, unlike the original's `until docker ps; do sleep 2; done`, which
# spins forever if the daemon never comes back and takes the health check down
# with it.
ensure_docker() {
    if ! systemctl is-active --quiet docker; then
        log "ERROR: Docker not running. Starting..."
        systemctl start docker
    fi
    local i
    for i in $(seq 1 15); do
        if docker ps >/dev/null 2>&1; then
            [ "$i" -gt 1 ] && log "Docker became available after ${i}s"
            return 0
        fi
        sleep 1
    done
    log "CRITICAL: Docker daemon unavailable after 15s, modules will be unreliable"
    send_slack_notification "🚨 Docker daemon down" \
        "The health check could not reach the Docker daemon after 15s. Container checks and auto-recovery are not functioning." "🚨"
    return 1
}

# Start Health Check
log "Starting modular health check run..."

# Global Checks
ensure_docker
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
