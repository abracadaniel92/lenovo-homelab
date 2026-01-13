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
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "127.0.0.1:8080" "$CONFIG_FILE"; then
            log "WARNING: Detected 127.0.0.1 in cloudflared config. Fixing to localhost for stability..."
            sed -i 's/127.0.0.1:8080/localhost:8080/g' "$CONFIG_FILE"
            # We don't restart here, the main loop will catch service down if this was the cause
        fi
    fi
}

# Function to check Caddyfile for problematic gzip settings (prevents mobile download issues)
check_caddyfile_integrity() {
    CADDYFILE="/home/docker-projects/caddy/config/Caddyfile"
    if [ -f "$CADDYFILE" ]; then
        # Check for encode gzip in mobile-sensitive services (causes Cloudflare double-compression)
        PROBLEMATIC_SERVICES=("@jellyfin" "@paperless" "@vault" "@tickets" "@cloud")
        for service in "${PROBLEMATIC_SERVICES[@]}"; do
            # Check if service block has encode gzip
            if grep -A10 "$service" "$CADDYFILE" | grep -q "encode gzip"; then
                local warning_msg="WARNING: Detected 'encode gzip' in $service block. This causes mobile download/blank page issues!"
                local action_msg="ACTION REQUIRED: Remove 'encode gzip' from $service in Caddyfile to fix mobile access"
                log "$warning_msg"
                log "$action_msg"
                
                # Send Slack notification
                local slack_title="Homelab Alert: Caddyfile Configuration Issue"
                local slack_message="@here

*Service:* \`$service\`
*Issue:* \`encode gzip\` detected in Caddyfile
*Impact:* Mobile browsers download .txt files instead of rendering pages

*Action Required:*
Remove \`encode gzip\` from the \`$service\` block in:
\`$CADDYFILE\`

*View log:*
\`sudo tail -50 /var/log/enhanced-health-check.log\`"
                
                send_slack_notification "$slack_title" "$slack_message" "⚠️"
                # Don't auto-fix - requires manual review to ensure proper headers are in place
            fi
        done
    fi
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

# Check System Health
check_config_integrity
check_caddyfile_integrity
check_udp_buffers

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
