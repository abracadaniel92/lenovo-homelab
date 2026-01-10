#!/bin/bash
###############################################################################
# Fix Health Check Timer - Updates timer to 3-minute interval
###############################################################################

echo "🔧 Updating Enhanced Health Check Timer to 3-minute interval..."
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
Description=Run Enhanced Health Check Every 3 Minutes
Requires=enhanced-health-check.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=3min
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

if [ "$INTERVAL" = "3min" ] || [ "$INTERVAL" = "180s" ] || [ "$INTERVAL" = "180000000" ]; then
    echo "   ✓ Timer interval is correct: $INTERVAL (3 minutes)"
elif [ -n "$INTERVAL" ] && [ "$INTERVAL" != "unknown" ]; then
    # Check if it's in microseconds
    if echo "$INTERVAL" | grep -qE "^[0-9]+$"; then
        INTERVAL_SEC=$((INTERVAL / 1000000))
        if [ "$INTERVAL_SEC" = "180" ]; then
            echo "   ✓ Timer interval is correct: ${INTERVAL_SEC}s (3 minutes)"
        else
            echo "   ⚠️  Timer interval is ${INTERVAL_SEC}s (expected 180s/3min)"
        fi
    else
        echo "   ⚠️  Timer interval is: $INTERVAL (expected 3min or 180s)"
    fi
else
    echo "   ⚠️  Could not verify interval. Check manually:"
    echo "      systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value"
    echo "      cat $TIMER_FILE | grep OnUnitActiveSec"
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
echo "🎉 Health check timer updated! It will now run every 3 minutes."

