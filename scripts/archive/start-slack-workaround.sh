#!/bin/bash
###############################################################################
# Start Slack - Workaround for Snap Cgroup Issue
# Uses various methods to start Slack when snap cgroup is unavailable
###############################################################################

echo "Attempting to start Slack with workarounds..."

# Method 1: Try using dbus-launch to create proper session
echo "Method 1: Trying dbus-launch..."
if command -v dbus-launch > /dev/null 2>&1; then
    eval $(dbus-launch --sh-syntax)
    export DISPLAY=${DISPLAY:-:10.0}
    /usr/bin/snap run slack > /tmp/slack-dbus.log 2>&1 &
    sleep 3
    if pgrep -f slack > /dev/null; then
        echo "✓ Slack started with dbus-launch!"
        exit 0
    fi
fi

# Method 2: Try using systemd-run to create proper cgroup
echo "Method 2: Trying systemd-run..."
if systemctl --user is-active > /dev/null 2>&1; then
    systemd-run --user --scope -p Slice=app.slice /usr/bin/snap run slack > /tmp/slack-systemd.log 2>&1 &
    sleep 3
    if pgrep -f slack > /dev/null; then
        echo "✓ Slack started with systemd-run!"
        exit 0
    fi
fi

# Method 3: Try launching from a new shell session
echo "Method 3: Trying new shell session..."
DISPLAY=${DISPLAY:-:10.0} nohup bash -c '/usr/bin/snap run slack' > /tmp/slack-nohup.log 2>&1 &
sleep 3
if pgrep -f slack > /dev/null; then
    echo "✓ Slack started in new shell!"
    exit 0
fi

# Method 4: Check if we can use the desktop environment's application launcher
echo "Method 4: Instructions for manual launch..."
echo ""
echo "If automatic methods failed, try these:"
echo ""
echo "1. Launch Slack from your desktop application menu"
echo "   (GNOME: Activities -> Applications -> Slack)"
echo ""
echo "2. Use gtk-launch:"
echo "   gtk-launch slack_slack.desktop"
echo ""
echo "3. If using XRDP/VNC, make sure you're in a proper graphical session"
echo ""
echo "4. Try logging out and back in to reset the session cgroup"
echo ""
echo "5. As a last resort, reinstall Slack:"
echo "   sudo snap remove slack"
echo "   sudo snap install slack"

# Show any error logs
echo ""
echo "Error logs from attempts:"
for log in /tmp/slack-*.log; do
    if [ -f "$log" ]; then
        echo "--- $log ---"
        cat "$log" | head -10
        echo ""
    fi
done












