#!/bin/bash
###############################################################################
# Emergency Fix - Restore All Services
# Run this when everything is down
###############################################################################

echo "=========================================="
echo "Emergency Service Recovery"
echo "=========================================="
echo ""

# Start Docker if not running
if ! systemctl is-active --quiet docker; then
    echo "Starting Docker..."
    sudo systemctl start docker
    sleep 5
fi

# Wait for Docker
until docker ps > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    sleep 2
done

# Start Caddy (CRITICAL)
echo "Starting Caddy..."
cd /mnt/ssd/docker-projects/caddy || { echo "ERROR: Caddy directory not found!"; exit 1; }
docker compose up -d
sleep 5

# Start other Docker containers
echo "Starting Docker containers..."
cd /mnt/ssd/docker-projects/travelsync && docker compose up -d || echo "WARNING: travelsync failed"
cd /mnt/ssd/docker-projects/goatcounter && docker compose up -d || echo "WARNING: goatcounter failed"
cd /mnt/ssd/docker-projects/uptime-kuma && docker compose up -d || echo "WARNING: uptime-kuma failed"
cd /mnt/ssd/apps/nextcloud && docker compose up -d || echo "WARNING: nextcloud failed"
cd /mnt/ssd/docker-projects/kitchenowl && docker compose up -d || echo "WARNING: kitchenowl failed"
cd /mnt/ssd/docker-projects/jellyfin && docker compose up -d || echo "WARNING: jellyfin failed"

# Start systemd services
echo "Starting systemd services..."
sudo systemctl start cloudflared.service
sudo systemctl start planning-poker.service
sudo systemctl start gokapi.service
sudo systemctl start bookmarks.service

sleep 5

# Check status
echo ""
echo "=== Status ==="
docker ps --format "{{.Names}}: {{.Status}}" | grep -E "caddy|travelsync|nextcloud"
systemctl is-active cloudflared.service planning-poker.service gokapi.service bookmarks.service

echo ""
echo "Done! Services should be recovering..."

