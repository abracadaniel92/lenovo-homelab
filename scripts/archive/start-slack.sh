#!/bin/bash
###############################################################################
# Start Slack Desktop App
# Ensures Slack starts properly with all necessary environment variables
###############################################################################

echo "Starting Slack desktop app..."

# Set display if not set
if [ -z "$DISPLAY" ]; then
    # Try common displays
    if [ -S "/tmp/.X11-unix/X0" ]; then
        export DISPLAY=:0
    elif [ -S "/tmp/.X11-unix/X10" ]; then
        export DISPLAY=:10.0
    else
        # Try to get display from current session
        export DISPLAY=$(echo $XDG_SESSION_DESKTOP | grep -oP 'DISPLAY=\K[^ ]+' || echo ":0")
    fi
    echo "Set DISPLAY=$DISPLAY"
fi

# Fix document portal directory (create symlink if needed)
if [ ! -d "/run/user/$(id -u)/doc" ] && [ -d "$HOME/.cache/doc" ]; then
    echo "Creating document portal symlink..."
    sudo mkdir -p "/run/user/$(id -u)/doc" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Note: Could not create /run/user/$(id -u)/doc (may need sudo)"
    fi
fi

# Kill any existing Slack processes if requested
if [ "$1" == "--restart" ]; then
    echo "Stopping existing Slack processes..."
    pkill -f slack 2>/dev/null
    sleep 2
fi

# Check if Slack is already running
if pgrep -f "slack" > /dev/null 2>&1; then
    echo "Slack is already running:"
    pgrep -a slack | grep -v python
    echo ""
    read -p "Kill and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        pkill -f slack
        sleep 2
    else
        echo "Keeping existing Slack process."
        exit 0
    fi
fi

# Start Slack
echo "Launching Slack..."
echo "Display: $DISPLAY"
echo ""

# Try to start Slack and capture any errors
slack > /tmp/slack-output.log 2>&1 &
SLACK_PID=$!

# Wait a moment to see if it starts
sleep 3

# Check if process is still running
if ps -p $SLACK_PID > /dev/null 2>&1; then
    echo "✓ Slack started successfully (PID: $SLACK_PID)"
    echo ""
    echo "If Slack window doesn't appear, check:"
    echo "  cat /tmp/slack-output.log"
    echo ""
    echo "To see all Slack processes:"
    echo "  ps aux | grep slack | grep -v grep"
else
    echo "⚠️  Slack process exited. Checking error log..."
    echo ""
    cat /tmp/slack-output.log
    echo ""
    echo "Common solutions:"
    echo "1. If 'cannot connect to X server':"
    echo "   - Make sure you're logged into a graphical session"
    echo "   - Try: export DISPLAY=:0 && slack"
    echo ""
    echo "2. If running via SSH:"
    echo "   - Enable X11 forwarding: ssh -X user@host"
    echo "   - Or use VNC/remote desktop"
    echo ""
    echo "3. Reinstall Slack:"
    echo "   sudo snap remove slack && sudo snap install slack"
fi












