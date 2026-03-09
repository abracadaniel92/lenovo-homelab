#!/bin/bash
###############################################################################
# Deploy Enhanced Health Check to Production
# Copies updated script to /usr/local/bin/ and reloads systemd
###############################################################################

set -e

SCRIPT_SOURCE="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/enhanced-health-check.sh"
SCRIPT_DEST="/usr/local/bin/enhanced-health-check.sh"

echo "🚀 Deploying Enhanced Health Check to Production"
echo "================================================"
echo ""

# Check source file exists
if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo "❌ ERROR: Source file not found: $SCRIPT_SOURCE"
    exit 1
fi

# Backup current production script
if [ -f "$SCRIPT_DEST" ]; then
    BACKUP_FILE="${SCRIPT_DEST}.backup.$(date +%Y%m%d-%H%M%S)"
    echo "📋 Backing up current script to: $BACKUP_FILE"
    sudo cp "$SCRIPT_DEST" "$BACKUP_FILE"
    echo "   ✅ Backup created"
fi

# Copy new script
echo ""
echo "📦 Copying updated script to production..."
sudo cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
sudo chmod +x "$SCRIPT_DEST"
echo "   ✅ Script copied and made executable"

# Verify syntax
echo ""
echo "🔍 Verifying script syntax..."
if bash -n "$SCRIPT_DEST"; then
    echo "   ✅ Syntax valid"
else
    echo "   ❌ Syntax error detected!"
    echo "   Restoring backup..."
    if [ -f "$BACKUP_FILE" ]; then
        sudo cp "$BACKUP_FILE" "$SCRIPT_DEST"
        echo "   ✅ Backup restored"
    fi
    exit 1
fi

# Check for new features
echo ""
echo "🔍 Verifying new features..."
if grep -q "check_memory_usage" "$SCRIPT_DEST" && grep -q "check_disk_space" "$SCRIPT_DEST"; then
    echo "   ✅ Memory and disk monitoring found"
else
    echo "   ⚠️  WARNING: Memory/disk monitoring not found in deployed script"
fi

# Reload systemd
echo ""
echo "🔄 Reloading systemd..."
sudo systemctl daemon-reload
echo "   ✅ Systemd reloaded"

# Show timer status
echo ""
echo "📊 Health Check Timer Status:"
systemctl status enhanced-health-check.timer --no-pager | head -10 || echo "   ⚠️  Timer status check failed"

# Show next run time
echo ""
echo "⏰ Next Health Check Run:"
systemctl list-timers enhanced-health-check.timer --no-pager | tail -1 || echo "   ⚠️  Could not determine next run time"

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "Summary:"
echo "  • Script deployed: $SCRIPT_DEST"
echo "  • Lines: $(wc -l < "$SCRIPT_DEST")"
echo "  • Features: Memory & Disk monitoring"
echo "  • Status: Active (runs every hour)"
echo ""
echo "The health check will now monitor:"
echo "  • Memory usage (warns at 85%, critical at 90%)"
echo "  • Disk space on / (warns at 80%, critical at 90%)"
echo "  • Disk space on /mnt/ssd (warns at 80%, critical at 90%)"
echo ""
echo "Notifications will be sent to Mattermost when thresholds are exceeded."




