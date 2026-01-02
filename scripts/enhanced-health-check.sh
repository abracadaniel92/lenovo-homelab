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
    log "CRITICAL: External access down detected. Running fix-subdomains-down.sh..."
    FIX_SCRIPT="/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
    if [ -f "$FIX_SCRIPT" ]; then
        # Run the fix script (it will handle sudo internally)
        bash "$FIX_SCRIPT" >> "$LOG_FILE" 2>&1
        log "Fix script executed. Waiting 10 seconds for services to recover..."
        sleep 10
        
        # Verify fix worked
        if check_external_access "gmojsoski.com"; then
            log "SUCCESS: External access restored after fix"
        else
            log "WARNING: External access still down after fix. May need manual intervention."
        fi
    else
        log "ERROR: Fix script not found at $FIX_SCRIPT"
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

log "Health check complete"
