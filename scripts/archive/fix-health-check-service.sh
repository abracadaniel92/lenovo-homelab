#!/bin/bash
###############################################################################
# Fix Health Check Service
# Fixes the failing service-health-check.service
###############################################################################

echo "Fixing health check service..."

# Remove broken symlink if it exists
SYSTEM_SCRIPT="/usr/local/bin/health-check-and-restart.sh"
if [ -L "$SYSTEM_SCRIPT" ]; then
    echo "Removing broken symlink..."
    sudo rm "$SYSTEM_SCRIPT"
fi

# Check if script exists in repo
REPO_SCRIPT="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/health-check-and-restart.sh"

if [ -f "$REPO_SCRIPT" ]; then
    echo "Copying health check script to /usr/local/bin..."
    sudo cp "$REPO_SCRIPT" "$SYSTEM_SCRIPT"
    sudo chmod +x "$SYSTEM_SCRIPT"
    echo "✅ Script installed"
else
    echo "❌ Repo script not found, creating from template..."
    sudo tee "$SYSTEM_SCRIPT" > /dev/null << 'HEALTH_EOF'
#!/bin/bash
###############################################################################
# Health Check and Auto-Restart Script
###############################################################################

LOG_FILE="/var/log/service-health-check.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Wait for Docker
until docker ps > /dev/null 2>&1; do
    log "Waiting for Docker..."
    sleep 2
done

# Check and restart Docker containers
for container in caddy goatcounter uptime-kuma nextcloud-app nextcloud-postgres documents-to-calendar; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        log "Container $container is not running!"
        case $container in
            caddy) cd /mnt/ssd/docker-projects/caddy && docker compose up -d ;;
            goatcounter) cd /mnt/ssd/docker-projects/goatcounter && docker compose up -d ;;
            uptime-kuma) cd /mnt/ssd/docker-projects/uptime-kuma && docker compose up -d ;;
            nextcloud-app|nextcloud-postgres) cd /mnt/ssd/apps/nextcloud && docker compose up -d ;;
            documents-to-calendar) cd /mnt/ssd/docker-projects/documents-to-calendar && docker compose up -d ;;
        esac
    fi
done

# Check and restart systemd services
for service in cloudflared.service gokapi.service bookmarks.service planning-poker.service; do
    if ! systemctl is-active --quiet "$service"; then
        log "Service $service is not running!"
        systemctl restart "$service"
    fi
done

log "Health check complete"
HEALTH_EOF
    sudo chmod +x "$SYSTEM_SCRIPT"
    echo "✅ Script created"
fi

# Reload systemd
sudo systemctl daemon-reload

# Restart the service
sudo systemctl restart service-health-check.service
sleep 2

# Check status
echo ""
echo "Health check service status:"
systemctl status service-health-check.service --no-pager | head -10

echo ""
echo "✅ Health check service fixed!"
