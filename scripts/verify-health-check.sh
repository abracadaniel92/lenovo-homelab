#!/bin/bash
###############################################################################
# Verify Health Check Configuration
# Checks that the health check timer is properly configured with 3-minute interval
###############################################################################

echo "🔍 Verifying Enhanced Health Check Configuration..."
echo ""

# Check if systemd timer exists
if [ ! -f "/etc/systemd/system/enhanced-health-check.timer" ]; then
    echo "❌ Timer file not found: /etc/systemd/system/enhanced-health-check.timer"
    echo "   Run: sudo bash scripts/permanent-auto-recovery.sh"
    exit 1
else
    echo "✅ Timer file exists: /etc/systemd/system/enhanced-health-check.timer"
fi

# Check if service file exists
if [ ! -f "/etc/systemd/system/enhanced-health-check.service" ]; then
    echo "❌ Service file not found: /etc/systemd/system/enhanced-health-check.service"
    echo "   Run: sudo bash scripts/permanent-auto-recovery.sh"
    exit 1
else
    echo "✅ Service file exists: /etc/systemd/system/enhanced-health-check.service"
fi

# Check timer interval (multiple methods)
INTERVAL=$(systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value 2>/dev/null || echo "")
TIMER_FILE="/etc/systemd/system/enhanced-health-check.timer"

# If systemctl can't read it, check the file directly
if [ -z "$INTERVAL" ]; then
    if [ -f "$TIMER_FILE" ]; then
        INTERVAL_FROM_FILE=$(grep -E "^OnUnitActiveSec=" "$TIMER_FILE" | cut -d= -f2 | tr -d ' ')
        if [ -n "$INTERVAL_FROM_FILE" ]; then
            INTERVAL="$INTERVAL_FROM_FILE"
            echo "✅ Timer interval (from file): $INTERVAL"
            if [ "$INTERVAL" = "3min" ] || [ "$INTERVAL" = "180s" ]; then
                echo "   ✓ Interval is correct (3 minutes)"
            else
                echo "   ⚠️  Interval is $INTERVAL (expected 3min or 180s)"
                echo "   To fix: sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer"
            fi
        else
            echo "⚠️  Warning: Could not read timer interval from file"
        fi
    else
        echo "⚠️  Warning: Timer file not found"
    fi
elif [ "$INTERVAL" = "3min" ] || [ "$INTERVAL" = "180s" ] || [ "$INTERVAL" = "180000000" ] || [ "$INTERVAL" = "3 min" ]; then
    echo "✅ Timer interval is correct: $INTERVAL (3 minutes)"
else
    # Convert microseconds to seconds for comparison
    if echo "$INTERVAL" | grep -qE "^[0-9]+$"; then
        INTERVAL_SEC=$((INTERVAL / 1000000))
        if [ "$INTERVAL_SEC" = "180" ]; then
            echo "✅ Timer interval is correct: $INTERVAL_SEC seconds (3 minutes)"
        else
            echo "⚠️  Warning: Timer interval is ${INTERVAL_SEC}s (expected 180s/3min)"
            echo "   To fix, update the timer file and reload: sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer"
        fi
    else
        echo "⚠️  Warning: Timer interval is $INTERVAL (expected 3min or 180s)"
        echo "   To fix, update the timer file and reload: sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer"
    fi
fi

# Check if timer is enabled
if systemctl is-enabled enhanced-health-check.timer >/dev/null 2>&1; then
    echo "✅ Timer is enabled"
else
    echo "⚠️  Warning: Timer is not enabled. Run: sudo systemctl enable enhanced-health-check.timer"
fi

# Check if timer is active
if systemctl is-active enhanced-health-check.timer >/dev/null 2>&1; then
    echo "✅ Timer is active (running)"
    
    # Show next run time
    NEXT_RUN=$(systemctl list-timers enhanced-health-check.timer --no-legend 2>/dev/null | awk '{print $1, $2, $3}' || echo "Unknown")
    if [ "$NEXT_RUN" != "Unknown" ]; then
        echo "   Next run: $NEXT_RUN"
    fi
else
    echo "⚠️  Warning: Timer is not active. Run: sudo systemctl start enhanced-health-check.timer"
fi

# Check if script exists
if [ -f "/usr/local/bin/enhanced-health-check.sh" ]; then
    echo "✅ Health check script exists: /usr/local/bin/enhanced-health-check.sh"
    
    # Check if script is executable
    if [ -x "/usr/local/bin/enhanced-health-check.sh" ]; then
        echo "✅ Script is executable"
    else
        echo "⚠️  Warning: Script is not executable. Run: sudo chmod +x /usr/local/bin/enhanced-health-check.sh"
    fi
else
    echo "⚠️  Warning: Script not found at /usr/local/bin/enhanced-health-check.sh"
    echo "   Check if it exists in the repo: scripts/enhanced-health-check.sh"
fi

# Check log file
LOG_FILE="/var/log/enhanced-health-check.log"
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo "0")
    LAST_LOG=$(tail -1 "$LOG_FILE" 2>/dev/null | cut -c1-50 || echo "No entries")
    echo "✅ Log file exists: $LOG_FILE (size: $LOG_SIZE bytes)"
    echo "   Last log entry: $LAST_LOG"
else
    echo "ℹ️  Log file doesn't exist yet (will be created on first run): $LOG_FILE"
fi

echo ""
echo "📋 Summary:"
echo "   - To check timer status: systemctl status enhanced-health-check.timer"
echo "   - To view logs: tail -f /var/log/enhanced-health-check.log"
echo "   - To manually run: sudo bash /usr/local/bin/enhanced-health-check.sh"
echo "   - To reload timer after changes: sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer"

