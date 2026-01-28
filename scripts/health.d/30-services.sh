#!/bin/bash
# 30-services.sh: Health check for miscellaneous services

# Check TravelSync
if ! check_service_http "http://localhost:8000/api/health" 5; then
    log "WARNING: TravelSync not responding. Restarting..."
    cd /mnt/ssd/docker-projects/travelsync
    docker compose restart
    sleep 5
fi

# Check individual systemd services
for service in "gokapi.service" "bookmarks.service" "planning-poker.service"; do
    if ! systemctl is-active --quiet "$service"; then
        log "WARNING: $service not running. Restarting..."
        sudo systemctl restart "$service"
        sleep 2
    fi
done

# Check Bookmarks specifically for port 5000 conflict
if ! check_service_http "http://localhost:5000/" 5; then
    log "WARNING: Bookmarks service not answering on port 5000"
    
    # Check if port 5000 is occupied by something else (e.g. AirPlay on macOS, though less likely on Linux)
    if ss -tuln | grep -q ":5000 "; then
        log "ERROR: Port 5000 is occupied by another process"
    elif ! systemctl is-active --quiet bookmarks.service; then
         log "WARNING: Bookmarks service stopped. Restarting..."
         sudo systemctl restart bookmarks.service
    fi
fi
