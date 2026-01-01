#!/bin/bash
###############################################################################
# Fix Downtime Issues - December 30, 2025
# Run with: sudo bash fix-downtime-issues.sh
###############################################################################

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run with sudo"
    echo "   Usage: sudo bash fix-downtime-issues.sh"
    exit 1
fi

echo "=========================================="
echo "Fixing Downtime Issues"
echo "=========================================="
echo ""

# 1. Set UDP buffer sizes permanently
echo "1. Setting UDP buffer sizes permanently..."
sysctl -w net.core.rmem_max=8388608 > /dev/null
sysctl -w net.core.rmem_default=8388608 > /dev/null

# Add to /etc/sysctl.conf if not already there
if ! grep -q "net.core.rmem_max=8388608" /etc/sysctl.conf; then
    echo "" >> /etc/sysctl.conf
    echo "# Cloudflare tunnel UDP buffer sizes (added by fix-downtime-issues.sh)" >> /etc/sysctl.conf
    echo "net.core.rmem_max=8388608" >> /etc/sysctl.conf
    echo "net.core.rmem_default=8388608" >> /etc/sysctl.conf
    echo "   ✅ Added to /etc/sysctl.conf"
else
    echo "   ✅ Already in /etc/sysctl.conf"
fi
echo "   ✅ UDP buffers set"

# 2. Check if service watchdog exists and enable it
echo ""
echo "2. Checking service watchdog..."
if [ -f "/etc/systemd/system/service-watchdog.timer" ]; then
    systemctl enable service-watchdog.timer
    systemctl start service-watchdog.timer
    echo "   ✅ Service watchdog enabled and started"
else
    echo "   ⚠️  Service watchdog timer not found"
    echo "   Run: bash permanent-auto-recovery.sh to set it up"
fi

# 3. Restart Cloudflare tunnel to apply UDP buffer changes
echo ""
echo "3. Restarting Cloudflare tunnel..."
systemctl restart cloudflared.service
sleep 3
if systemctl is-active --quiet cloudflared.service; then
    echo "   ✅ Cloudflare tunnel restarted"
else
    echo "   ❌ Cloudflare tunnel failed to start"
    systemctl status cloudflared.service --no-pager | head -10
fi

# 4. Verify timers
echo ""
echo "4. Verifying monitoring timers..."
if systemctl is-active --quiet enhanced-health-check.timer; then
    echo "   ✅ Enhanced health check timer: active"
else
    echo "   ⚠️  Enhanced health check timer: inactive"
fi

if systemctl is-active --quiet service-watchdog.timer; then
    echo "   ✅ Service watchdog timer: active"
else
    echo "   ⚠️  Service watchdog timer: inactive"
fi

echo ""
echo "=========================================="
echo "Fix Complete"
echo "=========================================="
echo ""
echo "✅ UDP buffer sizes set permanently"
echo "✅ Service watchdog enabled (if available)"
echo "✅ Cloudflare tunnel restarted"
echo ""
echo "⚠️  CRITICAL: Configure Uptime Kuma notifications!"
echo "   See: usefull files/KUMA_ALERT_FIX_CRITICAL.md"
echo ""
echo "   All monitors show 'Resend Interval: 0' = NO ALERTS"
echo "   This must be fixed in the Uptime Kuma UI"
echo ""




