#!/bin/bash
###############################################################################
# Setup Fail2ban for SSH and Web Services Protection
# Protects against brute force attacks
###############################################################################

echo "=========================================="
echo "Setting up Fail2ban"
echo "=========================================="
echo ""

# Check if already installed
if command -v fail2ban-server &> /dev/null; then
    echo "✓ Fail2ban is already installed"
    systemctl status fail2ban --no-pager | head -5
    exit 0
fi

echo "1. Installing Fail2ban..."
sudo apt update
sudo apt install -y fail2ban

if [ $? -ne 0 ]; then
    echo "✗ Failed to install fail2ban"
    exit 1
fi

echo "✓ Fail2ban installed"
echo ""

echo "2. Creating local configuration..."
# Create local jail configuration
sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
# Ban IPs for 1 hour (3600 seconds)
bantime = 3600
# Time window to count failures (10 minutes)
findtime = 600
# Number of failures before ban
maxretry = 5
# Email notifications (uncomment and configure if needed)
# destemail = your-email@example.com
# sendername = Fail2Ban
# action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 5
bantime = 3600

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
EOF

echo "✓ Configuration created at /etc/fail2ban/jail.local"
echo ""

echo "3. Starting and enabling Fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

if systemctl is-active fail2ban >/dev/null 2>&1; then
    echo "✓ Fail2ban is running"
else
    echo "✗ Fail2ban failed to start"
    exit 1
fi

echo ""
echo "4. Checking status..."
sudo fail2ban-client status

echo ""
echo "5. Checking SSH jail status..."
sudo fail2ban-client status sshd

echo ""
echo "=========================================="
echo "Fail2ban Setup Complete!"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  • SSH: 5 failed attempts = 1 hour ban"
echo "  • Ban time: 3600 seconds (1 hour)"
echo "  • Time window: 600 seconds (10 minutes)"
echo ""
echo "Useful commands:"
echo "  • Check status: sudo fail2ban-client status"
echo "  • Check SSH jail: sudo fail2ban-client status sshd"
echo "  • Unban IP: sudo fail2ban-client set sshd unbanip <IP>"
echo "  • View banned IPs: sudo fail2ban-client status sshd"
echo "  • View logs: sudo tail -f /var/log/fail2ban.log"
echo ""

