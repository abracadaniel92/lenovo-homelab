#!/bin/bash
# Quick verification of enhanced-health-check.timer interval (run on server)

TIMER_FILE="/etc/systemd/system/enhanced-health-check.timer"

echo "=== Timer file (OnUnitActiveSec) ==="
grep "OnUnitActiveSec" "$TIMER_FILE" 2>/dev/null || echo "File not found or no match"

echo ""
echo "=== systemctl show (interval) ==="
interval=$(systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value 2>/dev/null)
if [ -n "$interval" ]; then
    echo "OnUnitActiveSec = $interval"
else
    echo "(empty - checking file instead)"
    grep "^OnUnitActiveSec=" "$TIMER_FILE" 2>/dev/null | cut -d= -f2
fi

echo ""
echo "=== Next run time ==="
systemctl list-timers enhanced-health-check.timer --no-pager 2>/dev/null || echo "Could not list timer"

echo ""
echo "=== Timer active? ==="
systemctl is-active enhanced-health-check.timer 2>/dev/null || echo "unknown"
