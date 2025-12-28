#!/bin/bash
###############################################################################
# Update Health Check Interval
# Changes health check from 5 minutes to 2 minutes for faster detection
###############################################################################

echo "Updating health check interval from 5 minutes to 2 minutes..."

# Update timer file
sudo tee /etc/systemd/system/service-health-check.timer > /dev/null << 'EOF'
[Unit]
Description=Run Service Health Check every 2 minutes
Requires=service-health-check.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=2min
Unit=service-health-check.service

[Install]
WantedBy=timers.target
EOF

# Reload systemd and restart timer
sudo systemctl daemon-reload
sudo systemctl restart service-health-check.timer

echo ""
echo "Health check interval updated!"
echo "  - Changed from 5 minutes to 2 minutes"
echo "  - Changed OnBootSec from 2min to 1min"
echo ""
echo "Checking status..."
systemctl status service-health-check.timer --no-pager | head -15

echo ""
echo "Next run:"
systemctl list-timers service-health-check.timer --no-pager

