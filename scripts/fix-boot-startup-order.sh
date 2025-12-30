#!/bin/bash
###############################################################################
# Fix Boot Startup Order
# Ensures services start in proper order to prevent downtime on boot
###############################################################################

echo "=========================================="
echo "Fixing Boot Startup Order"
echo "=========================================="
echo ""

# 1. Create systemd service to start Docker containers in order
echo "1. Creating Docker containers startup service..."

DOCKER_STARTUP_SERVICE="/etc/systemd/system/docker-containers-start.service"
sudo tee "$DOCKER_STARTUP_SERVICE" > /dev/null << 'EOF'
[Unit]
Description=Start Docker Containers in Order
After=docker.service network-online.target
Wants=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/start-docker-containers.sh

[Install]
WantedBy=multi-user.target
EOF

# 2. Create script to start containers in proper order
echo "2. Creating Docker containers startup script..."

START_CONTAINERS_SCRIPT="/usr/local/bin/start-docker-containers.sh"
sudo tee "$START_CONTAINERS_SCRIPT" > /dev/null << 'EOF'
#!/bin/bash
# Start Docker containers in proper order to prevent downtime

set -e

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Wait for Docker to be fully ready
log "Waiting for Docker to be ready..."
until docker ps > /dev/null 2>&1; do
    sleep 2
done
log "Docker is ready"

# Step 1: Start Caddy first (reverse proxy - needed by everything)
log "Starting Caddy..."
cd /mnt/ssd/docker-projects/caddy
docker compose up -d
sleep 3

# Wait for Caddy to be ready
until curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ | grep -q "200\|302"; do
    log "Waiting for Caddy to be ready..."
    sleep 2
done
log "Caddy is ready"

# Step 2: Start database services
log "Starting Nextcloud database..."
cd /mnt/ssd/apps/nextcloud
docker compose up -d db
sleep 2

# Step 3: Start application services
log "Starting application services..."

# Nextcloud app (depends on db)
cd /mnt/ssd/apps/nextcloud
docker compose up -d app
sleep 2

# TravelSync
log "Starting TravelSync..."
cd /mnt/ssd/docker-projects/documents-to-calendar
docker compose up -d
sleep 2

# Other services (can start in parallel)
log "Starting other services..."
cd /mnt/ssd/docker-projects/goatcounter && docker compose up -d &
cd /mnt/ssd/docker-projects/uptime-kuma && docker compose up -d &
cd /mnt/ssd/docker-projects/pihole && docker compose up -d &
wait

log "All Docker containers started"
EOF

sudo chmod +x "$START_CONTAINERS_SCRIPT"

# 3. Update Planning Poker service to wait for network and Docker
echo "3. Updating Planning Poker service dependencies..."

PLANNING_POKER_SERVICE="/etc/systemd/system/planning-poker.service"
if [ -f "$PLANNING_POKER_SERVICE" ]; then
    # Update to wait for network-online and Docker
    sudo sed -i '/\[Unit\]/a After=network-online.target docker.service docker-containers-start.service\nWants=network-online.target docker.service' "$PLANNING_POKER_SERVICE"
    sudo sed -i '/After=network.target/d' "$PLANNING_POKER_SERVICE"
fi

# 4. Update other systemd services to wait for Docker containers
echo "4. Updating systemd service dependencies..."

# Gokapi should wait for network
GOKAPI_SERVICE="/etc/systemd/system/gokapi.service"
if [ -f "$GOKAPI_SERVICE" ]; then
    if ! grep -q "After=network-online.target" "$GOKAPI_SERVICE"; then
        sudo sed -i '/\[Unit\]/a After=network-online.target\nWants=network-online.target' "$GOKAPI_SERVICE"
    fi
fi

# Bookmarks should wait for network
BOOKMARKS_SERVICE="/etc/systemd/system/bookmarks.service"
if [ -f "$BOOKMARKS_SERVICE" ]; then
    if ! grep -q "After=network-online.target" "$BOOKMARKS_SERVICE"; then
        sudo sed -i '/\[Unit\]/a After=network-online.target\nWants=network-online.target' "$BOOKMARKS_SERVICE"
    fi
fi

# Cloudflared already waits for Caddy, but ensure it waits for docker-containers-start
if [ -f "/etc/systemd/system/cloudflared.service" ]; then
    if ! grep -q "docker-containers-start.service" "/etc/systemd/system/cloudflared.service"; then
        sudo sed -i '/After=network.target docker.service/a After=docker-containers-start.service' "/etc/systemd/system/cloudflared.service"
        sudo sed -i '/Wants=docker.service/a Wants=docker-containers-start.service' "/etc/systemd/system/cloudflared.service"
    fi
fi

# 5. Ensure Docker service starts on boot
echo "5. Ensuring Docker starts on boot..."
sudo systemctl enable docker.service

# 6. Enable network-online target (if not already)
echo "6. Enabling network-online target..."
sudo systemctl enable NetworkManager-wait-online.service 2>/dev/null || \
sudo systemctl enable systemd-networkd-wait-online.service 2>/dev/null || \
echo "  Note: Network online service may vary by system"

# 7. Enable the new Docker containers startup service
echo "7. Enabling Docker containers startup service..."
sudo systemctl daemon-reload
sudo systemctl enable docker-containers-start.service

# 8. Test the startup script
echo "8. Testing startup script..."
if [ -f "$START_CONTAINERS_SCRIPT" ]; then
    echo "  Startup script created successfully"
else
    echo "  ERROR: Startup script not created!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "What was configured:"
echo "  ✓ Docker containers startup service created"
echo "  ✓ Containers will start in proper order:"
echo "    1. Caddy (reverse proxy)"
echo "    2. Nextcloud database"
echo "    3. Application services (Nextcloud, TravelSync, etc.)"
echo "    4. Other services (GoatCounter, Uptime Kuma, Pi-hole)"
echo "  ✓ Systemd services updated to wait for dependencies"
echo "  ✓ Planning Poker waits for network and Docker"
echo "  ✓ Cloudflared waits for Docker containers to start"
echo ""
echo "Startup order on boot:"
echo "  1. Docker service starts"
echo "  2. Network comes online"
echo "  3. Docker containers start in order"
echo "  4. Systemd services start (after their dependencies)"
echo ""
echo "To test the startup:"
echo "  sudo systemctl start docker-containers-start.service"
echo ""
echo "To check status:"
echo "  systemctl status docker-containers-start.service"
echo "  journalctl -u docker-containers-start.service -f"
echo ""

