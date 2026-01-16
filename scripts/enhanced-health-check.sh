#!/bin/bash
###############################################################################
# Enhanced Health Check with Auto-Recovery
###############################################################################

LOG_FILE="/var/log/enhanced-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB

# Rotate log
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Mattermost notification function (Slack-compatible format)
send_slack_notification() {
    local title="$1"
    local message="$2"
    local emoji="${3:-⚠️}"
    
    # Load webhook URL from .env if available
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/.env" ]; then
        source "$SCRIPT_DIR/.env"
    fi
    
    # Prioritize monitoring-specific webhook (Mattermost or legacy Slack)
    [ -n "$MONITORING_MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$MONITORING_MATTERMOST_WEBHOOK_URL"
    [ -n "$MONITORING_SLACK_WEBHOOK_URL" ] && [ -z "$MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$MONITORING_SLACK_WEBHOOK_URL"
    
    # Default Mattermost webhook for uptime/health monitoring (same as slack-pi-monitoring.sh)
    MATTERMOST_WEBHOOK_URL="${MATTERMOST_WEBHOOK_URL:-https://mattermost.gmojsoski.com/hooks/bettcnqps7ngpfp74i6zux5s8w}"
    
    if [ -z "$MATTERMOST_WEBHOOK_URL" ]; then
        log "WARNING: MATTERMOST_WEBHOOK_URL not set. Cannot send Mattermost notification."
        return 1
    fi
    
    # Build Mattermost message payload (Slack-compatible blocks format)
    read -r -d '' PAYLOAD << EOF || true
{
    "username": "System Bot",
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "${emoji} ${title}",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "${message}"
            }
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "Time: $(date '+%Y-%m-%d %H:%M:%S') | Host: $(hostname)"
                }
            ]
        }
    ]
}
EOF

    # Send to Mattermost (Slack-compatible format)
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST -H 'Content-type: application/json' \
        --data "$PAYLOAD" \
        "$MATTERMOST_WEBHOOK_URL" 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ] && [ "$BODY" = "ok" ]; then
        log "Mattermost notification sent successfully"
        return 0
    else
        log "WARNING: Failed to send Mattermost notification (HTTP $HTTP_CODE: $BODY)"
        return 1
    fi
}

check_service_http() {
    local url=$1
    local timeout=${2:-5}
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "303" ] || [ "$status" = "301" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check configuration integrity (prevents regression to 127.0.0.1)
check_config_integrity() {
    CONFIG_FILE="/home/goce/.cloudflared/config.yml"
    if [ ! -f "$CONFIG_FILE" ]; then
        log "ERROR: Cloudflare config file not found at $CONFIG_FILE"
        return 1
    fi
    
    # Check for 127.0.0.1 (unstable on this host setup)
    if grep -q "127.0.0.1:8080" "$CONFIG_FILE"; then
        log "WARNING: Detected 127.0.0.1 in cloudflared config. This causes intermittent failures!"
        log "Fixing to localhost:8080 for stability..."
        sed -i 's/127.0.0.1:8080/localhost:8080/g' "$CONFIG_FILE"
        
        # Verify fix
        if grep -q "127.0.0.1:8080" "$CONFIG_FILE"; then
            log "ERROR: Failed to fix Cloudflare config. Manual intervention required."
            send_slack_notification "🚨 Cloudflare Config Auto-Fix Failed" "@here

*Issue:* Cloudflare config contains \`127.0.0.1:8080\` (unstable)
*Auto-fix:* Failed
*Action:* Manual fix required

*File:* \`$CONFIG_FILE\`
*Command:* \`sed -i 's/127.0.0.1:8080/localhost:8080/g' $CONFIG_FILE\`

*Restart:* \`cd /home/docker-projects/cloudflared && docker compose restart\`" "🚨"
            return 1
        else
            log "SUCCESS: Cloudflare config fixed. Restarting tunnel..."
            send_slack_notification "✅ Cloudflare Config Auto-Fixed" "@here

*Issue:* Cloudflare config contained \`127.0.0.1:8080\` (unstable)
*Auto-fix:* ✅ Fixed to \`localhost:8080\`
*Action:* Tunnel will restart automatically" "✅"
            
            # Restart tunnel to apply fix
            cd /home/docker-projects/cloudflared || cd /mnt/ssd/docker-projects/cloudflared
            if docker compose restart >> "$LOG_FILE" 2>&1; then
                log "SUCCESS: Cloudflare tunnel restarted with fixed config"
            else
                log "WARNING: Cloudflare tunnel restart failed after config fix"
            fi
            return 0
        fi
    fi
    
    # Check that all ingress rules use localhost:8080 (required for stability)
    INGRESS_COUNT=$(grep -c "service:" "$CONFIG_FILE" || echo "0")
    LOCALHOST_COUNT=$(grep -c "service: http://localhost:8080" "$CONFIG_FILE" || echo "0")
    
    if [ "$INGRESS_COUNT" -gt 0 ] && [ "$LOCALHOST_COUNT" -lt "$INGRESS_COUNT" ]; then
        log "WARNING: Not all Cloudflare ingress rules use localhost:8080"
        log "Some services may have inconsistent external access"
        # Don't auto-fix this - might be intentional
    fi
    
    return 0
}

# Function to check Caddyfile for problematic gzip settings (prevents mobile download issues)
check_caddyfile_integrity() {
    # Check both main Caddyfile and split config files
    CADDYFILE_MAIN="/home/docker-projects/caddy/Caddyfile"
    CADDYFILE_CONFIG="/home/docker-projects/caddy/config/Caddyfile"
    CADDYFILE_DIR="/home/docker-projects/caddy/config.d"
    
    # Determine which Caddyfile location exists (production might use config/ subdirectory)
    if [ -f "$CADDYFILE_CONFIG" ]; then
        CADDYFILE="$CADDYFILE_CONFIG"
    elif [ -f "$CADDYFILE_MAIN" ]; then
        CADDYFILE="$CADDYFILE_MAIN"
    else
        log "WARNING: Caddyfile not found at $CADDYFILE_MAIN or $CADDYFILE_CONFIG"
        return 1
    fi
    
    # Check for encode gzip in mobile-sensitive services (causes Cloudflare double-compression)
    PROBLEMATIC_SERVICES=("@jellyfin" "@paperless" "@vault" "@tickets" "@cloud")
    
    for service in "${PROBLEMATIC_SERVICES[@]}"; do
        # Check main Caddyfile
        if grep -A10 "$service" "$CADDYFILE" 2>/dev/null | grep -q "encode gzip"; then
            local warning_msg="WARNING: Detected 'encode gzip' in $service block. This causes mobile download/blank page issues!"
            log "$warning_msg"
            send_caddyfile_warning "$service" "$CADDYFILE"
        fi
        
        # Check split config files if they exist
        if [ -d "$CADDYFILE_DIR" ]; then
            for config_file in "$CADDYFILE_DIR"/*.caddyfile; do
                if [ -f "$config_file" ] && grep -A10 "$service" "$config_file" 2>/dev/null | grep -q "encode gzip"; then
                    local config_name=$(basename "$config_file")
                    log "WARNING: Detected 'encode gzip' in $service block in split config: $config_name"
                    send_caddyfile_warning "$service" "$config_file" "$config_name"
                fi
            done
        fi
    done
}

# Helper function to send Caddyfile warning notifications
send_caddyfile_warning() {
    local service=$1
    local file_path=$2
    local config_name=${3:-""}
    
    local slack_title="Homelab Alert: Caddyfile Configuration Issue"
    local file_ref="$file_path"
    [ -n "$config_name" ] && file_ref="$config_name (in config.d/)"
    
    local slack_message="@here

*Service:* \`$service\`
*Issue:* \`encode gzip\` detected in Caddyfile
*Impact:* Mobile browsers download .txt files instead of rendering pages

*Action Required:*
Remove \`encode gzip\` from the \`$service\` block in:
\`$file_ref\`

*View log:*
\`sudo tail -50 /var/log/enhanced-health-check.log\`"
    
    send_slack_notification "$slack_title" "$slack_message" "⚠️"
    # Don't auto-fix - requires manual review to ensure proper headers are in place
}

check_udp_buffers() {
    local TARGET_BUFFER=26214400 # 25MB
    local rmem_max=$(sysctl -n net.core.rmem_max)
    if [ "$rmem_max" -lt $TARGET_BUFFER ]; then
        log "WARNING: UDP receive buffer too small ($rmem_max). Fixing..."
        if sudo sysctl -w net.core.rmem_max=$TARGET_BUFFER >> "$LOG_FILE" 2>&1; then
            log "SUCCESS: UDP receive buffer increased to 25MB"
        else
            log "ERROR: Failed to increase UDP buffer"
        fi
    fi
    
    local wmem_max=$(sysctl -n net.core.wmem_max)
    if [ "$wmem_max" -lt $TARGET_BUFFER ]; then
        log "WARNING: UDP send buffer too small ($wmem_max). Fixing..."
        if sudo sysctl -w net.core.wmem_max=$TARGET_BUFFER >> "$LOG_FILE" 2>&1; then
            log "SUCCESS: UDP send buffer increased to 25MB"
        else
            log "ERROR: Failed to increase UDP buffer"
        fi
    fi
}

# Check Memory Usage
check_memory_usage() {
    # Get memory usage percentage (used/total * 100)
    MEM_INFO=$(free | awk '/^Mem:/')
    MEM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
    MEM_USED=$(echo "$MEM_INFO" | awk '{print $3}')
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
    MEM_TOTAL_GB=$(free -h | awk '/^Mem:/ {print $2}')
    MEM_USED_GB=$(free -h | awk '/^Mem:/ {print $3}')
    
    # Thresholds
    MEM_WARNING_THRESHOLD=85
    MEM_CRITICAL_THRESHOLD=90
    
    # Notification throttling (only alert once per hour for same issue)
    MEM_ALERT_FILE="/tmp/memory-alert-sent"
    CURRENT_HOUR=$(date +%Y%m%d-%H)
    
    if [ "$MEM_PERCENT" -ge "$MEM_CRITICAL_THRESHOLD" ]; then
        log "CRITICAL: Memory usage at ${MEM_PERCENT}% (${MEM_USED_GB}/${MEM_TOTAL_GB})"
        
        # Check if we already sent alert this hour
        if [ ! -f "$MEM_ALERT_FILE" ] || [ "$(cat "$MEM_ALERT_FILE" 2>/dev/null)" != "$CURRENT_HOUR" ]; then
            send_slack_notification "🚨 CRITICAL: High Memory Usage" "@all

*Memory Usage:* ${MEM_PERCENT}% (${MEM_USED_GB} / ${MEM_TOTAL_GB})
*Status:* CRITICAL (≥ ${MEM_CRITICAL_THRESHOLD}%)

*Action:* Consider:
  • Restarting heavy containers
  • Checking for memory leaks
  • Reviewing resource limits

*Check:* \`free -h\`
*Log:* \`sudo tail -50 $LOG_FILE\`" "🚨"
            echo "$CURRENT_HOUR" > "$MEM_ALERT_FILE"
        fi
        return 1
    elif [ "$MEM_PERCENT" -ge "$MEM_WARNING_THRESHOLD" ]; then
        log "WARNING: Memory usage at ${MEM_PERCENT}% (${MEM_USED_GB}/${MEM_TOTAL_GB})"
        
        # Check if we already sent alert this hour
        if [ ! -f "$MEM_ALERT_FILE" ] || [ "$(cat "$MEM_ALERT_FILE" 2>/dev/null)" != "$CURRENT_HOUR" ]; then
            send_slack_notification "⚠️ WARNING: High Memory Usage" "@here

*Memory Usage:* ${MEM_PERCENT}% (${MEM_USED_GB} / ${MEM_TOTAL_GB})
*Status:* Warning (≥ ${MEM_WARNING_THRESHOLD}%)

*Monitor:* Check resource usage and consider restarting heavy containers if needed.

*Check:* \`free -h\`
*Log:* \`sudo tail -50 $LOG_FILE\`" "⚠️"
            echo "$CURRENT_HOUR" > "$MEM_ALERT_FILE"
        fi
        return 0
    else
        # Memory is OK - clear alert file if it exists
        [ -f "$MEM_ALERT_FILE" ] && rm -f "$MEM_ALERT_FILE"
        log "Memory usage OK: ${MEM_PERCENT}% (${MEM_USED_GB}/${MEM_TOTAL_GB})"
        return 0
    fi
}

# Check Disk Space
check_disk_space() {
    local mount=$1
    local name=$2
    local warning_threshold=80
    local critical_threshold=90
    
    # Notification throttling per mount point
    local alert_file="/tmp/disk-alert-${name//\//-}-sent"
    local current_hour=$(date +%Y%m%d-%H)
    
    # Check if mount point exists
    if ! mountpoint -q "$mount" 2>/dev/null && [ ! -d "$mount" ]; then
        log "WARNING: Mount point not found: $mount"
        return 0
    fi
    
    # Get disk usage percentage (remove % sign)
    local disk_usage=$(df "$mount" 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_info=$(df -h "$mount" 2>/dev/null | awk 'NR==2 {print $3" / "$2" ("$5")"}')
    local disk_available=$(df -h "$mount" 2>/dev/null | awk 'NR==2 {print $4}')
    
    if [ -z "$disk_usage" ]; then
        log "WARNING: Could not get disk usage for $mount"
        return 0
    fi
    
    if [ "$disk_usage" -ge "$critical_threshold" ]; then
        log "CRITICAL: Disk space on $name ($mount) at ${disk_usage}% - ${disk_info}"
        
        # Check if we already sent alert this hour
        if [ ! -f "$alert_file" ] || [ "$(cat "$alert_file" 2>/dev/null)" != "$current_hour" ]; then
            send_slack_notification "🚨 CRITICAL: Low Disk Space - ${name}" "@all

*Mount:* ${name} (\`${mount}\`)
*Usage:* ${disk_usage}% - ${disk_info}
*Available:* ${disk_available}
*Status:* CRITICAL (≥ ${critical_threshold}%)

*Action:* Free up space immediately:
  • Clean old backups
  • Remove unused Docker images/volumes: \`docker system prune -a\`
  • Check large files: \`du -sh /* 2>/dev/null | sort -h | tail -10\`

*Check:* \`df -h ${mount}\`
*Log:* \`sudo tail -50 $LOG_FILE\`" "🚨"
            echo "$current_hour" > "$alert_file"
        fi
        return 1
    elif [ "$disk_usage" -ge "$warning_threshold" ]; then
        log "WARNING: Disk space on $name ($mount) at ${disk_usage}% - ${disk_info}"
        
        # Check if we already sent alert this hour
        if [ ! -f "$alert_file" ] || [ "$(cat "$alert_file" 2>/dev/null)" != "$current_hour" ]; then
            send_slack_notification "⚠️ WARNING: Low Disk Space - ${name}" "@here

*Mount:* ${name} (\`${mount}\`)
*Usage:* ${disk_usage}% - ${disk_info}
*Available:* ${disk_available}
*Status:* Warning (≥ ${warning_threshold}%)

*Monitor:* Consider cleaning up old files, backups, or Docker images.

*Check:* \`df -h ${mount}\`
*Log:* \`sudo tail -50 $LOG_FILE\`" "⚠️"
            echo "$current_hour" > "$alert_file"
        fi
        return 0
    else
        # Disk space is OK - clear alert file if it exists
        [ -f "$alert_file" ] && rm -f "$alert_file"
        log "Disk space OK on $name ($mount): ${disk_usage}% - ${disk_info}"
        return 0
    fi
}

# Check System Health
check_config_integrity
check_caddyfile_integrity
check_udp_buffers

# Check Memory and Disk Usage
check_memory_usage
check_disk_space "/" "Root"
check_disk_space "/mnt/ssd" "SSD"

# Check Backups (run once per hour to avoid excessive checks)
BACKUP_CHECK_FILE="/tmp/last-backup-check"
CURRENT_HOUR=$(date +%Y%m%d-%H)
if [ ! -f "$BACKUP_CHECK_FILE" ] || [ "$(cat "$BACKUP_CHECK_FILE" 2>/dev/null)" != "$CURRENT_HOUR" ]; then
    log "Running backup verification..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/verify-backups.sh" ]; then
        bash "$SCRIPT_DIR/verify-backups.sh" >> "$LOG_FILE" 2>&1 || {
            log "WARNING: Backup verification detected issues (check logs)"
        }
        echo "$CURRENT_HOUR" > "$BACKUP_CHECK_FILE"
    else
        log "WARNING: Backup verification script not found: $SCRIPT_DIR/verify-backups.sh"
    fi
fi

# Check Docker
if ! systemctl is-active --quiet docker; then
    log "ERROR: Docker not running. Starting..."
    sudo systemctl start docker
    sleep 10
fi

until docker ps > /dev/null 2>&1; do
    log "Waiting for Docker..."
    sleep 2
done

# Check Caddy (CRITICAL)
if ! check_service_http "http://localhost:8080/" 5; then
    log "CRITICAL: Caddy not responding. Restarting..."
    cd /mnt/ssd/docker-projects/caddy
    docker compose restart caddy
    sleep 5
    if ! check_service_http "http://localhost:8080/" 10; then
        log "CRITICAL: Caddy still not responding after restart!"
    else
        log "SUCCESS: Caddy is now responding"
    fi
fi

# Check Cloudflare Tunnel (external access - CRITICAL)
# Cloudflare tunnel runs as Docker containers, not systemd service
TUNNEL_RUNNING=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" | wc -l)
if [ "$TUNNEL_RUNNING" -lt 1 ]; then
    log "CRITICAL: Cloudflare tunnel not running. Restarting..."
    cd /home/docker-projects/cloudflared || cd /mnt/ssd/docker-projects/cloudflared
    docker compose up -d
    sleep 5
    # Verify it started
    TUNNEL_RUNNING_AFTER=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" | wc -l)
    if [ "$TUNNEL_RUNNING_AFTER" -ge 1 ]; then
        log "SUCCESS: Cloudflare tunnel restarted successfully"
    else
        log "ERROR: Cloudflare tunnel failed to start!"
    fi
fi

# Check external access (subdomain downtime detection)
check_external_access() {
    local domain=$1
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://${domain}" 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "303" ] || [ "$status" = "301" ]; then
        return 0
    else
        return 1
    fi
}

# Check if external access is down (502/404 errors)
EXTERNAL_DOWN=false
if ! check_external_access "gmojsoski.com"; then
    log "WARNING: External access down (gmojsoski.com not accessible)"
    EXTERNAL_DOWN=true
fi

# If external access is down, run fix-subdomains-down script
if [ "$EXTERNAL_DOWN" = true ]; then
    log "CRITICAL: External access down detected. Running fix-external-access.sh..."
    
    # Send Slack notification for critical outage
    local slack_title="🚨 CRITICAL: External Access Down"
    local slack_message="@all

*Domain:* gmojsoski.com
*Status:* Not accessible (502/404/503)
*Action:* Running fix-external-access.sh automatically

*Check log:*
\`sudo tail -50 /var/log/enhanced-health-check.log\`"
    send_slack_notification "$slack_title" "$slack_message" "🚨"
    
    FIX_SCRIPT="/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-external-access.sh"
    if [ -f "$FIX_SCRIPT" ]; then
        # Run the fix script (it will handle sudo internally)
        bash "$FIX_SCRIPT" >> "$LOG_FILE" 2>&1
        log "Fix script executed. Waiting 10 seconds for services to recover..."
        sleep 10
        
        # Verify fix worked
        if check_external_access "gmojsoski.com"; then
            log "SUCCESS: External access restored after fix"
            # Send recovery Slack notification
            send_slack_notification "✅ External Access Restored" "External access has been restored successfully after running the fix script." "✅"
        else
            log "WARNING: External access still down after fix. May need manual intervention."
            # Send failure Slack notification
            send_slack_notification "🚨 External Access Still Down" "@all

The fix script was executed but external access is still down. Manual intervention may be required.

*Check logs:* \`sudo tail -50 /var/log/enhanced-health-check.log\`" "🚨"
        fi
    else
        log "ERROR: Fix script not found at $FIX_SCRIPT"
        send_slack_notification "❌ Fix Script Not Found" "@here

The fix-external-access.sh script was not found at:
\`$FIX_SCRIPT\`

*Manual intervention required.*" "❌"
    fi
fi

# Check TravelSync
if ! check_service_http "http://localhost:8000/api/health" 5; then
    log "WARNING: TravelSync not responding. Restarting..."
    cd /mnt/ssd/docker-projects/documents-to-calendar
    docker compose restart
    sleep 3
fi

# Check Planning Poker
if ! check_service_http "http://localhost:3000/" 5; then
    log "WARNING: Planning Poker not responding. Restarting..."
    sudo systemctl restart planning-poker.service
    sleep 2
fi

# Check Linkwarden
if ! check_service_http "http://localhost:8090/" 5; then
    log "WARNING: Linkwarden not responding. Restarting..."
    cd /home/docker-projects/linkwarden
    docker compose restart
    sleep 3
fi

# Check Nextcloud
if ! check_service_http "http://localhost:8081/" 5; then
    log "WARNING: Nextcloud not responding. Restarting..."
    cd /mnt/ssd/apps/nextcloud
    docker compose restart app
    sleep 3
fi

# Check Jellyfin
if ! check_service_http "http://localhost:8096/" 5; then
    log "WARNING: Jellyfin not responding. Restarting..."
    cd /mnt/ssd/docker-projects/jellyfin
    docker compose restart
    sleep 3
fi

# Check other services
for service in "gokapi.service" "bookmarks.service"; do
    if ! systemctl is-active --quiet "$service"; then
        log "WARNING: $service not running. Restarting..."
        sudo systemctl restart "$service"
        sleep 2
    fi
done

# Check Bookmarks specifically for port 5000 conflict
if ! check_service_http "http://localhost:5000/" 5; then
    log "WARNING: Bookmarks service not answering on port 5000"
    
    # Check if port 5000 is occupied by something else
    PORT_USER=$(sudo lsof -t -i:5000 -sTCP:LISTEN 2>/dev/null)
    BOOKMARKS_PID=$(systemctl show -p MainPID bookmarks.service | cut -d= -f2)
    
    if [ -n "$PORT_USER" ] && [ "$PORT_USER" != "$BOOKMARKS_PID" ] && [ "$BOOKMARKS_PID" != "0" ]; then
        PROCESS_NAME=$(ps -p $PORT_USER -o comm=)
        log "CRITICAL: Port 5000 conflict denied! Used by PID $PORT_USER ($PROCESS_NAME). Killing..."
        sudo kill -9 $PORT_USER
        sleep 2
        sudo systemctl restart bookmarks.service
        log "Restarted bookmarks service after preserving port 5000"
    elif ! systemctl is-active --quiet bookmarks.service; then
         log "WARNING: Bookmarks service stopped. Restarting..."
         sudo systemctl restart bookmarks.service
    fi
fi

log "Health check complete"
