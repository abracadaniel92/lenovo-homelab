#!/bin/bash
# Setup Reliability Improvements
# Run this with: sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/setup-reliability-improvements.sh"

set -e

echo "========================================"
echo "  RELIABILITY IMPROVEMENTS SETUP"
echo "========================================"
echo ""

# 1. Create health check watchdog
echo "1. Creating health check watchdog..."
cat > /usr/local/bin/healthcheck-watchdog.sh << 'WATCHDOG'
#!/bin/bash
# Watchdog for health check timer
# Ensures the timer never stops running for long

TIMER="enhanced-health-check.timer"
LOG="/var/log/healthcheck-watchdog.log"

log() {
    echo "[$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG"
}

# Check if timer is active
if ! systemctl is-active --quiet "$TIMER"; then
    log "CRITICAL: $TIMER was stopped! Restarting..."
    systemctl start "$TIMER"
    
    # Verify it started
    sleep 2
    if systemctl is-active --quiet "$TIMER"; then
        log "SUCCESS: $TIMER restarted successfully"
    else
        log "FAILED: Could not restart $TIMER"
    fi
fi

# Also check cloudflared
if ! systemctl is-active --quiet cloudflared.service; then
    log "WARNING: cloudflared.service was stopped! Restarting..."
    systemctl start cloudflared.service
    sleep 5
    if systemctl is-active --quiet cloudflared.service; then
        log "SUCCESS: cloudflared restarted"
    else
        log "FAILED: Could not restart cloudflared"
    fi
fi
WATCHDOG
chmod +x /usr/local/bin/healthcheck-watchdog.sh
echo "   ✅ Watchdog script created"

# 2. Add to crontab if not exists
echo ""
echo "2. Adding watchdog to crontab..."
if grep -q "healthcheck-watchdog.sh" /etc/crontab; then
    echo "   Already in crontab"
else
    echo "*/5 * * * * root /usr/local/bin/healthcheck-watchdog.sh" >> /etc/crontab
    echo "   ✅ Added to crontab (runs every 5 minutes)"
fi

# 3. Create switch-to-docker-tunnel script
echo ""
echo "3. Creating Docker tunnel switch script..."
cat > /usr/local/bin/switch-to-docker-tunnel.sh << 'SWITCH'
#!/bin/bash
# Switches from systemd cloudflared to Docker-based HA tunnel

set -e

echo "=== Switching to Docker-based Cloudflare Tunnel ==="
echo ""

# Step 1: Create directory
echo "1. Setting up Docker project directory..."
mkdir -p /mnt/ssd/docker-projects/cloudflared

# Step 2: Copy docker-compose.yml
echo "2. Copying docker-compose configuration..."
COMPOSE_SRC="/home/goce/Desktop/Cursor projects/Pi-version-control/docker/cloudflared/docker-compose.yml"
if [ -f "$COMPOSE_SRC" ]; then
    cp "$COMPOSE_SRC" /mnt/ssd/docker-projects/cloudflared/
else
    echo "ERROR: docker-compose.yml not found"
    exit 1
fi

# Step 3: Stop systemd service
echo "3. Stopping systemd cloudflared service..."
systemctl stop cloudflared.service
systemctl disable cloudflared.service

# Step 4: Start Docker tunnel
echo "4. Starting Docker-based tunnel with replicas..."
cd /mnt/ssd/docker-projects/cloudflared
docker compose up -d

# Step 5: Wait and verify
echo "5. Waiting for tunnel to connect..."
sleep 10

# Check status
echo ""
echo "=== Tunnel Status ==="
docker compose ps

echo ""
echo "=== Recent Logs ==="
docker compose logs --tail 20

echo ""
echo "✅ Switch complete! Tunnel is now running in Docker with 2 replicas."
SWITCH
chmod +x /usr/local/bin/switch-to-docker-tunnel.sh
echo "   ✅ Switch script created"

# 4. Verify setup
echo ""
echo "========================================"
echo "  VERIFICATION"
echo "========================================"
echo ""
echo "Health check timer: $(systemctl is-active enhanced-health-check.timer)"
echo "Cloudflared: $(systemctl is-active cloudflared.service)"
echo "Watchdog in crontab: $(grep -c 'healthcheck-watchdog' /etc/crontab 2>/dev/null || echo 0) entries"

echo ""
echo "========================================"
echo "  SETUP COMPLETE"
echo "========================================"
echo ""
echo "What was set up:"
echo "  ✅ Health check watchdog (monitors the monitor)"
echo "  ✅ Crontab entry (runs watchdog every 5 min)"
echo "  ✅ Docker tunnel switch script"
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. [CRITICAL] Configure Kuma notifications:"
echo "   Open http://localhost:3001"
echo "   Settings → Notifications → Add Telegram/Email"
echo ""
echo "2. [RECOMMENDED] Switch to Docker tunnel with replicas:"
echo "   sudo /usr/local/bin/switch-to-docker-tunnel.sh"
echo ""
echo "3. [VERIFY] Test everything works:"
echo "   curl -I https://gmojsoski.com"
echo ""

