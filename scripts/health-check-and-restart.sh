#!/bin/bash
###############################################################################
# Health Check and Auto-Restart Script
# Monitors all services and restarts them if they're down
###############################################################################

LOG_FILE="/var/log/service-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB

# Rotate log if too large
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if Docker container is running
check_docker_container() {
    local container_name=$1
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# Function to restart Docker container
restart_docker_container() {
    local container_name=$1
    local compose_dir=$2
    local service_name=$3
    log "Restarting Docker container: $container_name"
    if [ -n "$compose_dir" ] && [ -d "$compose_dir" ]; then
        cd "$compose_dir"
        if [ -n "$service_name" ]; then
            docker compose up -d "$service_name" 2>&1 | tee -a "$LOG_FILE"
        else
            docker compose up -d 2>&1 | tee -a "$LOG_FILE"
        fi
    else
        docker start "$container_name" 2>&1 | tee -a "$LOG_FILE"
    fi
}

# Function to check systemd service
check_systemd_service() {
    local service_name=$1
    if systemctl is-active --quiet "$service_name"; then
        return 0
    else
        return 1
    fi
}

# Function to restart systemd service
restart_systemd_service() {
    local service_name=$1
    log "Restarting systemd service: $service_name"
    systemctl restart "$service_name" 2>&1 | tee -a "$LOG_FILE"
    sleep 2
    if systemctl is-active --quiet "$service_name"; then
        log "Service $service_name restarted successfully"
    else
        log "ERROR: Failed to restart service $service_name"
    fi
}

# Check Docker daemon
if ! systemctl is-active --quiet docker; then
    log "WARNING: Docker daemon is not running. Starting Docker..."
    systemctl start docker
    sleep 5
fi

# Wait for Docker to be ready
until docker ps > /dev/null 2>&1; do
    log "Waiting for Docker to be ready..."
    sleep 2
done

# Check and restart Docker containers
declare -A docker_containers=(
    ["caddy"]="/mnt/ssd/docker-projects/caddy:caddy"
    ["goatcounter"]="/mnt/ssd/docker-projects/goatcounter:goatcounter"
    ["uptime-kuma"]="/mnt/ssd/docker-projects/uptime-kuma:uptime-kuma"
    ["nextcloud-app"]="/mnt/ssd/apps/nextcloud:app"
    ["nextcloud-postgres"]="/mnt/ssd/apps/nextcloud:db"
    ["pihole"]="/mnt/ssd/docker-projects/pihole:pihole"
    ["documents-to-calendar"]="/mnt/ssd/docker-projects/documents-to-calendar:app"
)

for container in "${!docker_containers[@]}"; do
    if ! check_docker_container "$container"; then
        log "Container $container is not running!"
        IFS=':' read -r compose_dir service_name <<< "${docker_containers[$container]}"
        restart_docker_container "$container" "$compose_dir" "$service_name"
    fi
done

# Check and restart systemd services
systemd_services=("cloudflared.service" "gokapi.service" "bookmarks.service" "planning-poker.service")

for service in "${systemd_services[@]}"; do
    if ! check_systemd_service "$service"; then
        log "Service $service is not running!"
        restart_systemd_service "$service"
    fi
done

log "Health check complete"

