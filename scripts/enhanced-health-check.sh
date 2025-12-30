#!/bin/bash
###############################################################################
# Enhanced Health Check with Auto-Recovery
# Monitors all critical services and restarts them if they fail
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

# Check Caddy (CRITICAL - reverse proxy for all services)
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

# Check Cloudflare Tunnel (CRITICAL - external access)
if ! systemctl is-active --quiet cloudflared.service; then
    log "ERROR: Cloudflare tunnel not running. Restarting..."
    sudo systemctl restart cloudflared.service
    sleep 5
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

# Check KitchenOwl
if ! check_service_http "http://localhost:8092/" 5; then
    log "WARNING: KitchenOwl not responding. Restarting..."
    cd /mnt/ssd/docker-projects/kitchenowl
    docker compose restart
    sleep 3
fi

# Check Vaultwarden
if ! check_service_http "http://localhost:8082/" 5; then
    log "WARNING: Vaultwarden not responding. Restarting..."
    cd /mnt/ssd/docker-projects/vaultwarden
    docker compose restart
    sleep 3
fi

# Check systemd services
for service in "gokapi.service" "bookmarks.service"; do
    if ! systemctl is-active --quiet "$service"; then
        log "WARNING: $service not running. Restarting..."
        sudo systemctl restart "$service"
        sleep 2
    fi
done

log "Health check complete"

