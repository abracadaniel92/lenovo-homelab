#!/bin/bash
###############################################################################
# Ensure All Services Are Running
# Quick script to start all services if they're not running
###############################################################################

echo "Checking and starting all services..."

# Wait for Docker
until docker ps > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    systemctl start docker
    sleep 2
done

# Start Docker containers
echo "Starting Docker containers..."
cd /mnt/ssd/docker-projects/caddy && docker compose up -d
cd /mnt/ssd/docker-projects/goatcounter && docker compose up -d
cd /mnt/ssd/docker-projects/uptime-kuma && docker compose up -d
cd /mnt/ssd/docker-projects/pihole && docker compose up -d
cd /mnt/ssd/docker-projects/documents-to-calendar && docker compose up -d
cd /mnt/ssd/apps/nextcloud && docker compose up -d

# Start systemd services
echo "Starting systemd services..."
systemctl start cloudflared.service
systemctl start gokapi.service
systemctl start bookmarks.service
systemctl start planning-poker.service

# Show status
echo ""
echo "Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "Systemd services:"
systemctl is-active cloudflared.service gokapi.service bookmarks.service planning-poker.service

echo ""
echo "Done!"













