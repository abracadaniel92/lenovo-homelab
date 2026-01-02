#!/bin/bash
###############################################################################
# Enhanced Health Check with Auto-Recovery
# Checks all critical services and auto-restarts if down
###############################################################################

LOG_FILE="/var/log/enhanced-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB

# Rotate log if too large
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

restart_docker_service() {
    local name=$1
    local path=$2
    log "WARNING: $name not responding. Restarting..."
    cd "$path"
    docker compose restart
    sleep 5
}

# ============================================================================
# PHASE 1: Check Docker is running
# ============================================================================
if ! systemctl is-active --quiet docker; then
    log "CRITICAL: Docker not running. Starting..."
    sudo systemctl start docker
    sleep 10
fi

until docker ps > /dev/null 2>&1; do
    log "Waiting for Docker..."
    sleep 2
done

# ============================================================================
# PHASE 2: Check critical infrastructure (Caddy & Tunnel)
# ============================================================================

# Caddy (reverse proxy - CRITICAL)
if ! check_service_http "http://localhost:8080/" 5; then
    log "CRITICAL: Caddy not responding. Restarting..."
    cd /mnt/ssd/docker-projects/caddy
    docker compose restart
    sleep 5
fi

# Cloudflare Tunnel (external access - CRITICAL)
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

# ============================================================================
# PHASE 3: Check external access
# ============================================================================
check_external() {
    curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$1" 2>/dev/null
}

EXTERNAL_STATUS=$(check_external "gmojsoski.com")
if [ "$EXTERNAL_STATUS" != "200" ] && [ "$EXTERNAL_STATUS" != "302" ]; then
    log "CRITICAL: External access down (status: $EXTERNAL_STATUS). Restarting tunnel..."
    cd /mnt/ssd/docker-projects/cloudflared
    docker compose restart
    sleep 10
fi

# ============================================================================
# PHASE 4: Check all services
# ============================================================================

# KitchenOwl (shopping)
if ! check_service_http "http://localhost:8092/" 5; then
    restart_docker_service "KitchenOwl" "/mnt/ssd/docker-projects/kitchenowl"
fi

# Jellyfin
if ! check_service_http "http://localhost:8096/" 5; then
    restart_docker_service "Jellyfin" "/mnt/ssd/docker-projects/jellyfin"
fi

# Nextcloud
if ! check_service_http "http://localhost:8081/" 5; then
    restart_docker_service "Nextcloud" "/mnt/ssd/docker-projects/nextcloud"
fi

# Vaultwarden
if ! check_service_http "http://localhost:8082/" 5; then
    restart_docker_service "Vaultwarden" "/mnt/ssd/docker-projects/vaultwarden"
fi

# Uptime Kuma
if ! check_service_http "http://localhost:3001/" 5; then
    restart_docker_service "Uptime-Kuma" "/mnt/ssd/docker-projects/uptime-kuma"
fi


# GoatCounter (analytics)
if ! check_service_http "http://localhost:8088/" 5; then
    restart_docker_service "GoatCounter" "/mnt/ssd/docker-projects/goatcounter"
fi

# Gokapi (files)
if ! check_service_http "http://localhost:8091/" 5; then
    restart_docker_service "Gokapi" "/mnt/ssd/docker-projects/gokapi"
fi

# TravelSync
if ! check_service_http "http://localhost:8000/" 5; then
    restart_docker_service "TravelSync" "/mnt/ssd/docker-projects/travelsync"
fi

# Planning Poker
if ! check_service_http "http://localhost:3000/" 5; then
    log "WARNING: Planning Poker not responding. Restarting..."
    sudo systemctl restart planning-poker.service 2>/dev/null || true
    sleep 2
fi

# Bookmarks
if ! systemctl is-active --quiet bookmarks.service 2>/dev/null; then
    log "WARNING: Bookmarks service not running. Restarting..."
    sudo systemctl restart bookmarks.service 2>/dev/null || true
fi

log "Health check complete - all services checked"
