#!/bin/bash
###############################################################################
# Fix Slack Snap Cgroup Issue
# Resolves the "is not a snap cgroup" error that prevents Slack from starting
###############################################################################

echo "Fixing Slack snap cgroup issue..."

# The issue is that Slack (a snap app) needs to run in a snap cgroup
# When started from certain contexts (like systemd user session), it fails

# Solution 1: Try starting Slack directly (not via systemd)
echo "Attempting to start Slack directly..."

# Kill any existing Slack processes
pkill -f slack 2>/dev/null
sleep 1

# Set proper environment
export DISPLAY=${DISPLAY:-:10.0}

# Try starting Slack using snap run (which handles cgroups properly)
echo "Starting Slack via snap run..."
snap run slack > /tmp/slack-startup.log 2>&1 &
SLACK_PID=$!

sleep 3

# Check if it started
if ps -p $SLACK_PID > /dev/null 2>&1 || pgrep -f "slack" > /dev/null; then
    echo "✓ Slack started successfully!"
    echo ""
    echo "Slack processes:"
    ps aux | grep -i slack | grep -v grep | grep -v python
    exit 0
fi

# If that didn't work, check the error
echo "⚠️  Slack didn't start. Checking error log..."
cat /tmp/slack-startup.log

# Solution 2: Create a systemd user service that runs in proper context
echo ""
echo "Creating systemd user service for Slack..."

mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/slack.service << 'EOF'
[Unit]
Description=Slack Desktop
After=graphical-session.target

[Service]
Type=simple
Environment="DISPLAY=:10.0"
Environment="XDG_RUNTIME_DIR=/run/user/%U"
ExecStart=/usr/bin/snap run slack
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Reload systemd user daemon
systemctl --user daemon-reload

echo ""
echo "Systemd user service created. You can now:"
echo "  systemctl --user start slack"
echo "  systemctl --user enable slack  # to start on login"
echo ""
echo "Or try starting Slack directly from your desktop environment."

# Solution 3: Create desktop launcher that uses snap run
echo ""
echo "Creating desktop launcher..."

cat > ~/.local/share/applications/slack-fixed.desktop << EOF
[Desktop Entry]
Name=Slack (Fixed)
Comment=Team communication for the 21st century
Exec=/usr/bin/snap run slack
Icon=/snap/slack/current/usr/share/pixmaps/slack.png
Type=Application
Categories=Network;InstantMessaging;
StartupNotify=true
EOF

chmod +x ~/.local/share/applications/slack-fixed.desktop

echo "✓ Desktop launcher created: ~/.local/share/applications/slack-fixed.desktop"
echo ""
echo "Try launching 'Slack (Fixed)' from your application menu, or run:"
echo "  /usr/bin/snap run slack"












