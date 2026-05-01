#!/bin/bash
###############################################################################
# Deploy HDD health check to /usr/local/bin and enable systemd timer
# Run from anywhere: bash /path/to/Pi-version-control/scripts/deploy-hdd-health-check.sh
#
# Status: ACTIVE — manual deploy script. Run after editing
# scripts/hdd-health-check.sh to push the new version to /usr/local/bin/ and
# (re)enable the systemd timer at systemd/hdd-health-check.timer.
###############################################################################

set -e

# Repo root = parent of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Repo root: $REPO_DIR"
echo ""

# Copy script and module
echo "Copying scripts to /usr/local/bin..."
sudo cp "$REPO_DIR/scripts/hdd-health-check.sh" /usr/local/bin/
sudo chmod +x /usr/local/bin/hdd-health-check.sh
sudo mkdir -p /usr/local/bin/health.d
sudo cp "$REPO_DIR/scripts/health.d/40-disk-smart.sh" /usr/local/bin/health.d/

# Webhook (optional; skip if not present)
if [ -f "$REPO_DIR/scripts/health_webhook_url" ]; then
    sudo cp "$REPO_DIR/scripts/health_webhook_url" /usr/local/bin/
    echo "  health_webhook_url copied"
else
    echo "  WARNING: $REPO_DIR/scripts/health_webhook_url not found; create it or copy manually for Mattermost alerts"
fi

# Systemd units
echo "Installing systemd units..."
sudo cp "$REPO_DIR/systemd/hdd-health-check.service" "$REPO_DIR/systemd/hdd-health-check.timer" /etc/systemd/system/

# Reload and enable timer
echo "Enabling and starting timer..."
sudo systemctl daemon-reload
sudo systemctl enable --now hdd-health-check.timer

echo ""
echo "Done. Next run:"
systemctl list-timers hdd-health-check.timer --no-pager
