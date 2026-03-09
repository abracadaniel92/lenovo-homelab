#!/bin/bash
###############################################################################
# Fix Health Check Timer - Updates timer to 1-hour interval
###############################################################################

echo "🔧 Updating Enhanced Health Check Timer to 1-hour interval..."
echo ""

# Backup existing timer file
TIMER_FILE="/etc/systemd/system/enhanced-health-check.timer"
if [ -f "$TIMER_FILE" ]; then
    echo "📦 Creating backup of existing timer file..."
    sudo cp "$TIMER_FILE" "${TIMER_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Update the timer file
echo "📝 Updating timer file..."
sudo tee "$TIMER_FILE" > /dev/null << 'EOF'
[Unit]
Description=Run Enhanced Health Check Every Hour
Requires=enhanced-health-check.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=1h
AccuracySec=30s

[Install]
WantedBy=timers.target
EOF

# Reload systemd
echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload

# Restart the timer
echo "▶️  Restarting timer..."
sudo systemctl restart enhanced-health-check.timer

# Verify the interval
echo ""
echo "✅ Verification:"
INTERVAL=$(systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value 2>/dev/null || \
           grep -E "^OnUnitActiveSec=" "$TIMER_FILE" | cut -d= -f2 | tr -d ' ' || echo "unknown")

if [ "$INTERVAL" = "1h" ] || [ "$INTERVAL" = "3600s" ] || [ "$INTERVAL" = "3600000000" ]; then
    echo "   ✓ Timer interval is correct: $INTERVAL (1 hour)"
elif [ -n "$INTERVAL" ] && [ "$INTERVAL" != "unknown" ]; then
    # Check if it's in microseconds
    if echo "$INTERVAL" | grep -qE "^[0-9]+$"; then
        INTERVAL_SEC=$((INTERVAL / 1000000))
        if [ "$INTERVAL_SEC" = "3600" ]; then
            echo "   ✓ Timer interval is correct: ${INTERVAL_SEC}s (1 hour)"
        else
            echo "   ⚠️  Timer interval is ${INTERVAL_SEC}s (expected 3600s/1h)"
        fi
    else
        echo "   ⚠️  Timer interval is: $INTERVAL (expected 1h or 3600s)"
    fi
else
    echo "   ⚠️  Could not verify interval. Check manually:"
    echo "      systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value"
    echo "      cat $TIMER_FILE | grep OnUnitActiveSec"
    echo "   Expected: 1h or 3600s"
fi

# Check timer status
echo ""
if systemctl is-active enhanced-health-check.timer >/dev/null 2>&1; then
    echo "✅ Timer is active"
    NEXT_RUN=$(systemctl list-timers enhanced-health-check.timer --no-legend 2>/dev/null | awk '{print $1, $2, $3}' || echo "Unknown")
    echo "   Next run: $NEXT_RUN"
else
    echo "⚠️  Timer is not active. Starting..."
    sudo systemctl start enhanced-health-check.timer
fi

echo ""
echo "🎉 Health check timer updated! It will now run every hour."

