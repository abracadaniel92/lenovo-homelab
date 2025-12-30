#!/bin/bash
###############################################################################
# Fix Cloudflared Service Restart Policy
# Updates cloudflared.service to use Restart=always for maximum reliability
###############################################################################

echo "Fixing cloudflared.service restart policy..."

# Backup current service file
if [ -f /etc/systemd/system/cloudflared.service ]; then
    sudo cp /etc/systemd/system/cloudflared.service /etc/systemd/system/cloudflared.service.backup
    echo "Backed up current service file"
fi

# Update service file with Restart=always
sudo tee /etc/systemd/system/cloudflared.service > /dev/null << 'EOF'
[Unit]
Description=Cloudflare Tunnel
After=network.target docker.service
Wants=docker.service

[Service]
Type=simple
User=goce
ExecStartPre=/bin/sleep 10
ExecStartPre=/bin/bash -c 'until docker ps | grep -q caddy; do sleep 2; done'
ExecStart=/usr/local/bin/cloudflared tunnel --config /home/goce/.cloudflared/config.yml run
Restart=always
RestartSec=5s
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and restart service
sudo systemctl daemon-reload
sudo systemctl restart cloudflared.service

echo ""
echo "Cloudflared service updated!"
echo "  - Changed Restart=on-failure to Restart=always"
echo "  - Set RestartSec=5s"
echo "  - Set StartLimitInterval=0 (unlimited restarts)"
echo ""
echo "Checking status..."
sleep 2
systemctl status cloudflared.service --no-pager | head -15

echo ""
echo "To verify restart policy:"
echo "  systemctl show cloudflared.service -p Restart --value"

