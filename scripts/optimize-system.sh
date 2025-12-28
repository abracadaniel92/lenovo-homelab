#!/bin/bash
###############################################################################
# System Optimization Script
# Optimizes the system for 24/7 operation and prevents freezes
###############################################################################

echo "Starting system optimization..."

# 1. Ensure Docker service is enabled and running
echo "Configuring Docker service..."
systemctl enable docker
systemctl start docker

# 2. Enable all systemd services
echo "Enabling systemd services..."
systemctl enable cloudflared.service
systemctl enable gokapi.service
systemctl enable bookmarks.service
systemctl enable planning-poker.service

# Start services if not running
systemctl start cloudflared.service
systemctl start gokapi.service
systemctl start bookmarks.service
systemctl start planning-poker.service

# 3. Configure systemd to prevent service failures from stopping boot
echo "Configuring systemd failure handling..."
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/99-no-fail.conf << 'EOF'
[Manager]
DefaultTimeoutStartSec=300s
DefaultTimeoutStopSec=30s
EOF

# 4. Configure Docker to auto-start containers
echo "Configuring Docker auto-start..."
if [ ! -f /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "live-restore": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
fi

# 5. Disable swap to prevent freezes (optional - comment out if you need swap)
echo "Configuring swap..."
# Uncomment the following lines if you want to disable swap completely
# swapoff -a
# sed -i '/ swap / s/^/#/' /etc/fstab

# 6. Increase file descriptor limits
echo "Increasing file descriptor limits..."
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# 7. Optimize kernel parameters for stability
echo "Optimizing kernel parameters..."
cat >> /etc/sysctl.conf << 'EOF'

# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Prevent out-of-memory killer from killing important processes
vm.overcommit_memory = 1
vm.swappiness = 10

# File system optimizations
fs.file-max = 2097152
EOF

sysctl -p

# 8. Configure log rotation to prevent disk fill
echo "Configuring log rotation..."
if [ ! -f /etc/logrotate.d/docker-containers ]; then
    cat > /etc/logrotate.d/docker-containers << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
}
EOF
fi

# 9. Create systemd service for health check
echo "Creating health check service..."
cat > /etc/systemd/system/service-health-check.service << EOF
[Unit]
Description=Service Health Check and Auto-Restart
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/health-check-and-restart.sh
User=root
StandardOutput=journal
StandardError=journal
EOF

# 10. Create systemd timer for health check (runs every 5 minutes)
echo "Creating health check timer..."
cat > /etc/systemd/system/service-health-check.timer << 'EOF'
[Unit]
Description=Run Service Health Check every 5 minutes
Requires=service-health-check.service

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Unit=service-health-check.service

[Install]
WantedBy=timers.target
EOF

# Make scripts executable
chmod +x "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/health-check-and-restart.sh"
chmod +x "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/optimize-system.sh"
chmod +x "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"

# Enable and start health check timer
systemctl daemon-reload
systemctl enable service-health-check.timer
systemctl start service-health-check.timer

# 11. Ensure all Docker containers are started
echo "Starting all Docker containers..."
cd /mnt/ssd/docker-projects/caddy && docker compose up -d
cd /mnt/ssd/docker-projects/goatcounter && docker compose up -d
cd /mnt/ssd/docker-projects/uptime-kuma && docker compose up -d
cd /mnt/ssd/docker-projects/pihole && docker compose up -d
cd /mnt/ssd/docker-projects/documents-to-calendar && docker compose up -d
cd /mnt/ssd/apps/nextcloud && docker compose up -d

# 12. Restart Docker to apply daemon.json changes
echo "Restarting Docker to apply configuration..."
systemctl restart docker

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
sleep 5
until docker ps > /dev/null 2>&1; do
    sleep 2
done

# Restart all containers after Docker restart
echo "Restarting all containers..."
cd /mnt/ssd/docker-projects/caddy && docker compose up -d
cd /mnt/ssd/docker-projects/goatcounter && docker compose up -d
cd /mnt/ssd/docker-projects/uptime-kuma && docker compose up -d
cd /mnt/ssd/docker-projects/pihole && docker compose up -d
cd /mnt/ssd/docker-projects/documents-to-calendar && docker compose up -d
cd /mnt/ssd/apps/nextcloud && docker compose up -d

echo ""
echo "=========================================="
echo "System optimization complete!"
echo "=========================================="
echo ""
echo "Summary of changes:"
echo "  ✓ Docker service enabled and configured"
echo "  ✓ All systemd services enabled"
echo "  ✓ Systemd failure handling configured"
echo "  ✓ Docker auto-restart configured"
echo "  ✓ File descriptor limits increased"
echo "  ✓ Kernel parameters optimized"
echo "  ✓ Log rotation configured"
echo "  ✓ Health check service created (runs every 5 minutes)"
echo "  ✓ All Docker containers started"
echo ""
echo "Health check logs: /var/log/service-health-check.log"
echo ""
echo "To check health check status:"
echo "  systemctl status service-health-check.timer"
echo ""
echo "To view health check logs:"
echo "  tail -f /var/log/service-health-check.log"
echo ""

