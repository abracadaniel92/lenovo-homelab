#!/bin/bash
###############################################################################
# Fix Slack Desktop App
# Troubleshoots and fixes common Slack startup issues
###############################################################################

echo "Troubleshooting Slack desktop app..."

# Check if Slack is installed
if ! command -v slack > /dev/null 2>&1; then
    echo "ERROR: Slack is not installed!"
    echo "Install it with: sudo snap install slack"
    exit 1
fi

echo "✓ Slack is installed"

# Check snap status
echo ""
echo "Checking snap status..."
snap list slack

# Check if Slack is already running
if pgrep -f slack > /dev/null; then
    echo ""
    echo "⚠️  Slack appears to be running already:"
    pgrep -a slack
    read -p "Kill existing Slack processes and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f slack
        sleep 2
    else
        echo "Keeping existing processes."
        exit 0
    fi
fi

# Fix document portal warning (if needed)
if [ ! -d "/run/user/$(id -u)/doc" ]; then
    echo ""
    echo "Fixing document portal..."
    mkdir -p "/run/user/$(id -u)/doc" 2>/dev/null || echo "Note: May need sudo for /run/user directory"
fi

# Check snap connections
echo ""
echo "Checking snap connections..."
snap connections slack | grep -v "^-" || echo "All connections look good"

# Try to start Slack
echo ""
echo "Attempting to start Slack..."
echo "If running via SSH, make sure X11 forwarding is enabled or use: DISPLAY=:0 slack"

# Check if we have a display
if [ -z "$DISPLAY" ]; then
    # Try to detect display
    if [ -S "/tmp/.X11-unix/X0" ] || [ -S "/tmp/.X11-unix/X1" ]; then
        export DISPLAY=:0
        echo "Setting DISPLAY=:0"
    else
        echo "⚠️  WARNING: No DISPLAY environment variable set"
        echo "If you're on a remote session, you may need to set DISPLAY"
    fi
fi

# Start Slack in background and capture output
echo ""
echo "Starting Slack..."
slack > /tmp/slack-startup.log 2>&1 &
SLACK_PID=$!

sleep 3

# Check if it started
if ps -p $SLACK_PID > /dev/null 2>&1; then
    echo "✓ Slack started (PID: $SLACK_PID)"
    echo ""
    echo "Check if Slack window appeared. If not, check logs:"
    echo "  tail -f /tmp/slack-startup.log"
    echo ""
    echo "To see all Slack processes:"
    echo "  ps aux | grep slack"
else
    echo "⚠️  Slack process exited quickly. Checking logs..."
    cat /tmp/slack-startup.log
    echo ""
    echo "Common issues:"
    echo "1. No display available (if remote, use X11 forwarding or VNC)"
    echo "2. Missing dependencies"
    echo "3. Permission issues"
    echo ""
    echo "Try running manually to see errors:"
    echo "  slack"
fi

# Show current Slack processes
echo ""
echo "Current Slack processes:"
ps aux | grep -i slack | grep -v grep | grep -v python || echo "No Slack processes found"












