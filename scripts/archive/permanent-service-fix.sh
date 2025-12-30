#!/bin/bash
###############################################################################
# Permanent Service Fix
# Comprehensive monitoring and auto-recovery system to prevent downtime
###############################################################################

echo "=========================================="
echo "Permanent Service Fix - Auto-Recovery System"
echo "=========================================="
echo ""

# 1. Create enhanced health check with auto-recovery
echo "1. Creating enhanced health check with auto-recovery..."

ENHANCED_HEALTH_CHECK="/usr/local/bin/enhanced-health-check.sh"
sudo tee "$ENHANCED_HEALTH_CHECK" > /dev/null << 'ENHANCED_EOF'
#!/bin/bash
###############################################################################
# Enhanced Health Check with Auto-Recovery
# Monitors services and automatically fixes issues
###############################################################################

LOG_FILE="/var/log/enhanced-health-check.log"
MAX_LOG_SIZE=10485760  # 10MB

# Rotate log if too large
if [ -f "$LOG_FILE" ] && [ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null) -gt $MAX_LOG_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
    touch "$LOG_FILE"
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if service is responding
check_service_http() {
    local url=$1
    local timeout=${2:-5}
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null)
    if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "301" ]; then
        return 0
    else
        return 1
    fi
}

# Function to restart Docker container
restart_docker_container() {
    local container=$1
    local compose_dir=$2
    log "Restarting Docker container: $container"
    if [ -n "$compose_dir" ] && [ -d "$compose_dir" ]; then
        cd "$compose_dir"
        docker compose restart "$container" 2>&1 | tee -a "$LOG_FILE"
    else
        docker restart "$container" 2>&1 | tee -a "$LOG_FILE"
    fi
    sleep 3
}

# Function to restart systemd service
restart_systemd_service() {
    local service=$1
    log "Restarting systemd service: $service"
    systemctl restart "$service" 2>&1 | tee -a "$LOG_FILE"
    sleep 3
}

# Check Docker daemon
if ! systemctl is-active --quiet docker; then
    log "ERROR: Docker daemon is not running. Starting Docker..."
    systemctl start docker
    sleep 10
fi

# Wait for Docker to be ready
until docker ps > /dev/null 2>&1; do
    log "Waiting for Docker to be ready..."
    sleep 2
done

# Check Caddy (critical - reverse proxy)
if ! check_service_http "http://localhost:8080/" 5; then
    log "ERROR: Caddy is not responding. Restarting..."
    restart_docker_container "caddy" "/mnt/ssd/docker-projects/caddy"
    sleep 5
    if ! check_service_http "http://localhost:8080/" 10; then
        log "CRITICAL: Caddy still not responding after restart!"
    else
        log "SUCCESS: Caddy is now responding"
    fi
fi

# Check TravelSync
if ! check_service_http "http://localhost:8000/api/health" 5; then
    log "WARNING: TravelSync is not responding. Restarting..."
    restart_docker_container "documents-to-calendar" "/mnt/ssd/docker-projects/documents-to-calendar"
fi

# Check Planning Poker
if ! check_service_http "http://localhost:3000/" 5; then
    log "WARNING: Planning Poker is not responding. Restarting..."
    restart_systemd_service "planning-poker.service"
fi

# Check Nextcloud
if ! check_service_http "http://localhost:8081/" 5; then
    log "WARNING: Nextcloud is not responding. Restarting..."
    restart_docker_container "nextcloud-app" "/mnt/ssd/apps/nextcloud"
fi

# Check Cloudflare Tunnel
if ! systemctl is-active --quiet cloudflared.service; then
    log "ERROR: Cloudflare tunnel is not running. Restarting..."
    restart_systemd_service "cloudflared.service"
    sleep 5
    if ! systemctl is-active --quiet cloudflared.service; then
        log "CRITICAL: Cloudflare tunnel failed to start!"
    fi
else
    # Check if tunnel is actually working by testing external access
    # This is a simple check - if Caddy is up but external access fails, tunnel might be broken
    if check_service_http "http://localhost:8080/" 5; then
        # Try to verify tunnel is working (check if we can reach through tunnel)
        # Note: This is a basic check - full tunnel test would require external endpoint
        log "Cloudflare tunnel service is running"
    fi
fi

# Check Uptime Kuma
if ! check_service_http "http://localhost:3001/" 5; then
    log "WARNING: Uptime Kuma is not responding. Restarting..."
    restart_docker_container "uptime-kuma" "/mnt/ssd/docker-projects/uptime-kuma"
fi

# Check other critical services
for service in "gokapi.service" "bookmarks.service"; do
    if ! systemctl is-active --quiet "$service"; then
        log "WARNING: $service is not running. Restarting..."
        restart_systemd_service "$service"
    fi
done

log "Health check complete"
ENHANCED_EOF

sudo chmod +x "$ENHANCED_HEALTH_CHECK"

# 2. Create systemd service for enhanced health check
echo "2. Creating enhanced health check systemd service..."

ENHANCED_HEALTH_SERVICE="/etc/systemd/system/enhanced-health-check.service"
sudo tee "$ENHANCED_HEALTH_SERVICE" > /dev/null << EOF
[Unit]
Description=Enhanced Health Check with Auto-Recovery
After=network-online.target docker.service
Wants=network-online.target docker.service

[Service]
Type=oneshot
ExecStart=$ENHANCED_HEALTH_CHECK
User=root

[Install]
WantedBy=multi-user.target
EOF

ENHANCED_HEALTH_TIMER="/etc/systemd/system/enhanced-health-check.timer"
sudo tee "$ENHANCED_HEALTH_TIMER" > /dev/null << EOF
[Unit]
Description=Run Enhanced Health Check Every Minute
Requires=enhanced-health-check.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=1min
AccuracySec=10s

[Install]
WantedBy=timers.target
EOF

# 3. Update Cloudflare tunnel service with auto-restart and health check
echo "3. Enhancing Cloudflare tunnel service..."

CLOUDFLARED_SERVICE="/etc/systemd/system/cloudflared.service"
if [ -f "$CLOUDFLARED_SERVICE" ]; then
    # Ensure it has proper restart settings
    if ! grep -q "StartLimitInterval=0" "$CLOUDFLARED_SERVICE"; then
        sudo sed -i '/Restart=always/a StartLimitInterval=0' "$CLOUDFLARED_SERVICE"
    fi
    # Add watchdog-like restart on failure
    if ! grep -q "RestartSec=5s" "$CLOUDFLARED_SERVICE"; then
        sudo sed -i '/Restart=always/a RestartSec=5s' "$CLOUDFLARED_SERVICE"
    fi
fi

# 4. Create Cloudflare tunnel health check script
echo "4. Creating Cloudflare tunnel health check..."

CLOUDFLARED_HEALTH="/usr/local/bin/cloudflared-health-check.sh"
sudo tee "$CLOUDFLARED_HEALTH" > /dev/null << 'CLOUDFLARED_EOF'
#!/bin/bash
# Cloudflare Tunnel Health Check
# Restarts tunnel if it's not working properly

if ! systemctl is-active --quiet cloudflared.service; then
    echo "Cloudflare tunnel is not running. Restarting..."
    systemctl restart cloudflared.service
    exit 0
fi

# Check if tunnel process is actually running
if ! pgrep -f "cloudflared tunnel" > /dev/null; then
    echo "Cloudflare tunnel process not found. Restarting..."
    systemctl restart cloudflared.service
    exit 0
fi

# Check if we can reach localhost:8080 (Caddy) - if Caddy is up but external fails, tunnel might be broken
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ --max-time 5 | grep -q "200\|302"; then
    # Caddy is up - check if tunnel is actually forwarding (basic check)
    # If Caddy responds but external access fails, we might need to restart tunnel
    # This is a simplified check - full verification would require external endpoint test
    exit 0
else
    echo "Caddy is not responding. This might indicate a broader issue."
    exit 1
fi
CLOUDFLARED_EOF

sudo chmod +x "$CLOUDFLARED_HEALTH"

# 5. Create watchdog service for critical services
echo "5. Creating watchdog service for critical services..."

WATCHDOG_SERVICE="/etc/systemd/system/service-watchdog.service"
sudo tee "$WATCHDOG_SERVICE" > /dev/null << EOF
[Unit]
Description=Service Watchdog - Monitor and Restart Critical Services
After=network-online.target docker.service
Wants=network-online.target docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/service-watchdog.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

WATCHDOG_SCRIPT="/usr/local/bin/service-watchdog.sh"
sudo tee "$WATCHDOG_SCRIPT" > /dev/null << 'WATCHDOG_EOF'
#!/bin/bash
# Service Watchdog - Continuously monitors and restarts services

while true; do
    # Check Caddy
    if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ --max-time 3 | grep -q "200\|302"; then
        echo "[$(date)] Caddy not responding, restarting..."
        cd /mnt/ssd/docker-projects/caddy && docker compose restart caddy
        sleep 5
    fi
    
    # Check Cloudflare tunnel
    if ! systemctl is-active --quiet cloudflared.service; then
        echo "[$(date)] Cloudflare tunnel not running, restarting..."
        systemctl restart cloudflared.service
        sleep 5
    fi
    
    # Check Planning Poker
    if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ --max-time 3 | grep -q "200"; then
        if systemctl is-active --quiet planning-poker.service; then
            echo "[$(date)] Planning Poker not responding but service is active, restarting..."
            systemctl restart planning-poker.service
        fi
    fi
    
    sleep 30
done
WATCHDOG_EOF

sudo chmod +x "$WATCHDOG_SCRIPT"

# 6. Enable all services
echo "6. Enabling all monitoring services..."
sudo systemctl daemon-reload
sudo systemctl enable enhanced-health-check.timer
sudo systemctl enable service-watchdog.service
sudo systemctl start enhanced-health-check.timer
sudo systemctl start service-watchdog.service

# 7. Restart Cloudflare tunnel to apply fixes
echo "7. Restarting Cloudflare tunnel..."
sudo systemctl restart cloudflared.service

echo ""
echo "=========================================="
echo "Permanent Fix Complete!"
echo "=========================================="
echo ""
echo "What was configured:"
echo "  ✓ Enhanced health check (runs every minute)"
echo "  ✓ Service watchdog (continuous monitoring)"
echo "  ✓ Cloudflare tunnel auto-restart"
echo "  ✓ Auto-recovery for all critical services"
echo ""
echo "Monitoring:"
echo "  - Enhanced health check: Every 1 minute"
echo "  - Service watchdog: Continuous (30s intervals)"
echo "  - Logs: /var/log/enhanced-health-check.log"
echo ""
echo "To check status:"
echo "  systemctl status enhanced-health-check.timer"
echo "  systemctl status service-watchdog.service"
echo "  tail -f /var/log/enhanced-health-check.log"
echo ""
echo "Services will now auto-recover from failures! 🛡️"
echo ""

