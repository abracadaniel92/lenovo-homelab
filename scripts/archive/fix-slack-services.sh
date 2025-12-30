#!/bin/bash
# Fix Slack service files and reload systemd

echo "Fixing Slack service files..."

# Copy updated service files to systemd
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/slack-pi-monitoring.service" /etc/systemd/system/
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/slack-goatcounter-weekly.service" /etc/systemd/system/

# Reload systemd
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Test the services
echo ""
echo "Testing services..."
echo ""

echo "Testing Pi monitoring service:"
sudo systemctl start slack-pi-monitoring.service
sleep 2
if sudo systemctl is-active --quiet slack-pi-monitoring.service || [ $? -eq 0 ]; then
    echo "✓ Pi monitoring service completed successfully"
else
    echo "✗ Pi monitoring service failed"
    echo "Error details:"
    sudo journalctl -u slack-pi-monitoring.service --no-pager -n 10
fi

echo ""
echo "Testing GoatCounter weekly service:"
sudo systemctl start slack-goatcounter-weekly.service
sleep 2
if sudo systemctl is-active --quiet slack-goatcounter-weekly.service || [ $? -eq 0 ]; then
    echo "✓ GoatCounter weekly service completed successfully"
else
    echo "✗ GoatCounter weekly service failed"
    echo "Error details:"
    sudo journalctl -u slack-goatcounter-weekly.service --no-pager -n 10
fi

echo ""
echo "=========================================="
echo "Service Status"
echo "=========================================="
echo ""
echo "Pi Monitoring Service:"
sudo systemctl status slack-pi-monitoring.service --no-pager | head -15
echo ""
echo "GoatCounter Weekly Service:"
sudo systemctl status slack-goatcounter-weekly.service --no-pager | head -15
echo ""
echo "Recent logs:"
echo "Pi Monitoring:"
sudo journalctl -u slack-pi-monitoring.service --no-pager -n 5
echo ""
echo "GoatCounter Weekly:"
sudo journalctl -u slack-goatcounter-weekly.service --no-pager -n 5
echo ""
echo "If services failed, check full logs with:"
echo "  sudo journalctl -xeu slack-pi-monitoring.service"
echo "  sudo journalctl -xeu slack-goatcounter-weekly.service"
echo ""

