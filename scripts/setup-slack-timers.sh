#!/bin/bash
# Setup script for Slack monitoring timers
# This will install and enable the systemd timers for Slack notifications

echo "Setting up Slack monitoring timers..."

# Copy service and timer files to systemd
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/slack-pi-monitoring.service" /etc/systemd/system/
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/slack-pi-monitoring.timer" /etc/systemd/system/
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/slack-goatcounter-weekly.service" /etc/systemd/system/
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/slack-goatcounter-weekly.timer" /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the timers
echo "Enabling Pi monitoring timer (runs every 5 days)..."
sudo systemctl enable slack-pi-monitoring.timer
sudo systemctl start slack-pi-monitoring.timer

echo "Enabling GoatCounter weekly analytics timer (runs every Sunday at 10 AM)..."
sudo systemctl enable slack-goatcounter-weekly.timer
sudo systemctl start slack-goatcounter-weekly.timer

# Show status
echo ""
echo "=========================================="
echo "Timer Status"
echo "=========================================="
echo ""
echo "Pi Monitoring Timer:"
sudo systemctl status slack-pi-monitoring.timer --no-pager | head -10
echo ""
echo "GoatCounter Weekly Timer:"
sudo systemctl status slack-goatcounter-weekly.timer --no-pager | head -10
echo ""
echo "All active timers:"
systemctl list-timers --no-pager | grep -E "slack|NEXT|LAST"
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "To check timer status:"
echo "  sudo systemctl status slack-pi-monitoring.timer"
echo "  sudo systemctl status slack-goatcounter-weekly.timer"
echo ""
echo "To manually trigger a report:"
echo "  sudo systemctl start slack-pi-monitoring.service"
echo "  sudo systemctl start slack-goatcounter-weekly.service"
echo ""










