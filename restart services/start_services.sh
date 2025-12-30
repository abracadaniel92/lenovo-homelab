#!/bin/bash

###############################################################################
# Start Services Script
# Ensures all services start in the correct order on boot
###############################################################################

# Wait for Docker to be ready
until docker ps > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    sleep 2
done

# Start Caddy if not running
if ! docker ps | grep -q caddy; then
    echo "Starting Caddy..."
    cd /mnt/ssd/docker-projects/caddy
    docker compose up -d
fi

# Start other Docker services
cd /mnt/ssd/docker-projects/goatcounter
docker compose up -d

cd /mnt/ssd/docker-projects/uptime-kuma
docker compose up -d

# Wait a bit for services to be ready
sleep 5

echo "Services started"























