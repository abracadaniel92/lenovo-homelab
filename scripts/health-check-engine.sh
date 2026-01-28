#!/bin/bash
###############################################################################
# Modular Health Check Engine
# Dynamically executes check modules from health.d/
###############################################################################

LOG_FILE="/var/log/enhanced-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/health.d"

# Rotate log
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
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
    local status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$domain")
    if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 301 ] || [ "$status_code" -eq 302 ]; then
        return 0
    else
        return 1
    fi
}

check_config_integrity() {
    # Port checking logic from old script
    local problematic_configs=$(grep -l "127.0.0.1" /etc/caddy/config.d/*.caddy 2>/dev/null || true)
    if [ -n "$problematic_configs" ]; then
        log "WARNING: Found potential 127.0.0.1 in Caddy configs: $problematic_configs"
        # Optional: Auto-fix logic can be added here
    fi
}

check_memory_usage() {
    local mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    if (( $(echo "$mem_usage > 90.0" | bc -l) )); then
        log "CRITICAL: Memory usage at ${mem_usage}%"
        send_slack_notification "🚨 CRITICAL: High Memory Usage" "System memory usage is at ${mem_usage}%." "🚨"
    fi
}

check_disk_space() {
    local path=$1
    local label=$2
    local usage=$(df -h "$path" | tail -1 | awk '{print $5}' | sed 's/%//')
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
            source "$module"
        else
            log "Skipping non-executable module: $(basename "$module")"
        fi
    done
else
    log "ERROR: Modules directory not found: $MODULES_DIR"
fi

log "Modular health check run complete"
