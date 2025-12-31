#!/bin/bash
###############################################################################
# Enhanced Health Check with Auto-Recovery
# Updated for Docker-based Cloudflare Tunnel with replicas
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

# Check Cloudflare Tunnel (Docker-based with replicas)
TUNNEL_RUNNING=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" 2>/dev/null | wc -l)
if [ "$TUNNEL_RUNNING" -lt 1 ]; then
    log "ERROR: Cloudflare tunnel not running. Restarting..."
    cd /mnt/ssd/docker-projects/cloudflared
    docker compose up -d
    sleep 5
    
    # Verify at least one replica is running
    TUNNEL_RUNNING=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$TUNNEL_RUNNING" -ge 1 ]; then
        log "SUCCESS: Cloudflare tunnel restarted ($TUNNEL_RUNNING replicas running)"
    else
        log "CRITICAL: Cloudflare tunnel failed to start!"
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
# Only check if local Caddy is working
if check_service_http "http://localhost:8080/" 5; then
    if ! check_external_access "gmojsoski.com"; then
        log "WARNING: External access down (gmojsoski.com not accessible, but local services OK)"
        log "Attempting automatic fix..."
        
        # Restart Caddy
        log "Restarting Caddy..."
        cd /mnt/ssd/docker-projects/caddy && docker compose restart caddy
        sleep 5
        
        # Restart Cloudflare tunnel (Docker)
        log "Restarting Cloudflare tunnel..."
        cd /mnt/ssd/docker-projects/cloudflared && docker compose restart
        sleep 10
        
        # Verify fix worked
        if check_external_access "gmojsoski.com"; then
            log "SUCCESS: External access restored after automatic fix"
        else
            log "WARNING: External access still down. May need manual intervention or DNS propagation time."
        fi
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
    sudo systemctl restart planning-poker.service 2>/dev/null || true
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

# Check other services
for service in "gokapi.service" "bookmarks.service"; do
    if systemctl list-units --type=service | grep -q "$service"; then
        if ! systemctl is-active --quiet "$service"; then
            log "WARNING: $service not running. Restarting..."
            sudo systemctl restart "$service" 2>/dev/null || true
            sleep 2
        fi
    fi
done

log "Health check complete"
