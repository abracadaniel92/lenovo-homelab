#!/bin/bash
###############################################################################
# Fix Health Check Service
# Fixes the systemd service file to handle paths with spaces
###############################################################################

echo "Fixing health check service..."

# Create a symlink without spaces for the script
SCRIPT_PATH="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/health-check-and-restart.sh"
SYMLINK_PATH="/usr/local/bin/health-check-and-restart.sh"

if [ -f "$SCRIPT_PATH" ]; then
    # Create symlink
    sudo ln -sf "$SCRIPT_PATH" "$SYMLINK_PATH"
    echo "Created symlink: $SYMLINK_PATH -> $SCRIPT_PATH"
    
    # Update systemd service to use symlink
    sudo tee /etc/systemd/system/service-health-check.service > /dev/null << 'EOF'
[Unit]
Description=Service Health Check and Auto-Restart
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/health-check-and-restart.sh
User=root
StandardOutput=journal
StandardError=journal
EOF

    # Reload systemd and restart service
    sudo systemctl daemon-reload
    sudo systemctl enable service-health-check.timer
    sudo systemctl start service-health-check.timer
    
    echo ""
    echo "Health check service fixed!"
    echo "Testing service..."
    sudo systemctl start service-health-check.service
    sleep 2
    sudo systemctl status service-health-check.service --no-pager -l | head -20
    
    echo ""
    echo "Service status:"
    systemctl is-active service-health-check.timer && echo "✓ Timer is active" || echo "✗ Timer is not active"
else
    echo "ERROR: Script not found at $SCRIPT_PATH"
    exit 1
fi












