#!/bin/bash
###############################################################################
# Health Check and Auto-Restart Script
# Monitors all services and restarts them if they're down
# Run this as a systemd service or cron job
###############################################################################

LOG_FILE="/var/log/service-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB

# Rotate log if too large
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]; then
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
        # Use service name if provided, otherwise try container name, otherwise just up -d
        if [ -n "$service_name" ]; then
            docker compose up -d "$service_name" 2>&1 | tee -a "$LOG_FILE"
        else
            # Try to find service name from docker-compose.yml
            if [ -f "docker-compose.yml" ]; then
                # Try container name first, if that fails, just do up -d
                docker compose up -d "$container_name" 2>&1 | tee -a "$LOG_FILE" || \
                docker compose up -d 2>&1 | tee -a "$LOG_FILE"
            else
                docker compose up -d 2>&1 | tee -a "$LOG_FILE"
            fi
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
# Format: container_name:compose_dir:service_name (service_name optional)
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
        # Parse compose_dir:service_name
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

# Check port connectivity (basic health check)
ports_to_check=(8080 8081 8088 8091 5000 8000 3001)

for port in "${ports_to_check[@]}"; do
    if ! timeout 2 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        log "WARNING: Port $port is not responding"
    fi
done

# Check system resources
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    log "WARNING: High memory usage: ${MEMORY_USAGE}%"
fi

if [ "$DISK_USAGE" -gt 90 ]; then
    log "WARNING: High disk usage: ${DISK_USAGE}%"
fi

log "Health check completed. Memory: ${MEMORY_USAGE}%, Disk: ${DISK_USAGE}%"


