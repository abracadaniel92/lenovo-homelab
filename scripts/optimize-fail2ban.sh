#!/bin/bash
###############################################################################
# Optimize Fail2ban Configuration
# Adds recommended settings for better security
###############################################################################

echo "=========================================="
echo "Optimizing Fail2ban Configuration"
echo "=========================================="
echo ""

if ! command -v fail2ban-server &> /dev/null; then
    echo "✗ Fail2ban is not installed"
    echo "Run: sudo bash '/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/setup-fail2ban.sh'"
    exit 1
fi

# Detect local network
LOCAL_NETWORK=$(ip route | grep -E "192.168|10\." | head -1 | awk '{print $1}' | cut -d'/' -f1 | sed 's/\.[0-9]*$/\.0\/24/')
if [ -z "$LOCAL_NETWORK" ]; then
    LOCAL_NETWORK="192.168.1.0/24"
    echo "⚠ Could not detect local network, using default: $LOCAL_NETWORK"
else
    echo "✓ Detected local network: $LOCAL_NETWORK"
fi

echo ""
echo "1. Creating optimized configuration..."

# Backup existing config
if [ -f /etc/fail2ban/jail.local ]; then
    sudo cp /etc/fail2ban/jail.local /etc/fail2ban/jail.local.backup
    echo "✓ Backed up existing config to jail.local.backup"
fi

# Create optimized configuration
sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
# Ban IPs for 1 hour (3600 seconds) - first offense
bantime = 3600
# Extended ban for repeat offenders (24 hours)
bantime.increment = true
bantime.maxtime = 86400
bantime.factor = 2

# Time window to count failures (10 minutes)
findtime = 600
# Number of failures before ban
maxretry = 5

# Whitelist local network and localhost
ignoreip = 127.0.0.1/8 ::1 ${LOCAL_NETWORK}

# Email notifications (uncomment and configure if needed)
# destemail = your-email@example.com
# sendername = Fail2Ban
# action = %(action_mwl)s

# Use systemd backend for better performance
backend = systemd

[sshd]
enabled = true
port = ssh,222,223
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 3600
# Ban for 24 hours after 3 bans
bantime.increment = true
bantime.maxtime = 86400
bantime.factor = 2
findtime = 600

# Protect Nextcloud (if using Apache logs)
[nextcloud]
enabled = false
port = http,https
logpath = /var/log/nextcloud/access.log
maxretry = 5
bantime = 3600

# Protect Caddy (if logging enabled)
[caddy]
enabled = false
port = http,https
logpath = /var/log/caddy/access.log
maxretry = 10
bantime = 3600

# Protect Gokapi (if logging enabled)
[gokapi]
enabled = false
port = http,https
logpath = /var/log/gokapi/access.log
maxretry = 5
bantime = 3600
EOF

echo "✓ Configuration created"
echo ""

echo "2. Restarting Fail2ban..."
sudo systemctl restart fail2ban

if systemctl is-active fail2ban >/dev/null 2>&1; then
    echo "✓ Fail2ban restarted successfully"
else
    echo "✗ Fail2ban failed to restart"
    exit 1
fi

echo ""
echo "3. Verifying configuration..."
sudo fail2ban-client status

echo ""
echo "4. Checking SSH jail..."
sudo fail2ban-client status sshd

echo ""
echo "=========================================="
echo "Optimization Complete!"
echo "=========================================="
echo ""
echo "New Settings:"
echo "  • Local network whitelisted: ${LOCAL_NETWORK}"
echo "  • Progressive bans: 1h → 2h → 4h → 8h → 24h max"
echo "  • Systemd backend for better performance"
echo "  • SSH ports protected: 22, 222, 223"
echo ""
echo "Configuration file: /etc/fail2ban/jail.local"
echo "Backup saved to: /etc/fail2ban/jail.local.backup"
echo ""

