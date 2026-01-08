#!/bin/bash
###############################################################################
# Setup Email Notifications for Health Check
# Configures msmtp to send emails via Gmail SMTP
###############################################################################

set -e

echo "=========================================="
echo "Setting up Email Notifications"
echo "=========================================="
echo ""

# Check if msmtp is installed
if ! command -v msmtp >/dev/null 2>&1; then
    echo "Installing msmtp..."
    sudo apt-get update
    sudo apt-get install -y msmtp msmtp-mta
    echo "✅ msmtp installed"
else
    echo "✅ msmtp already installed"
fi

# Create msmtp config directory
mkdir -p ~/.msmtprc
chmod 600 ~/.msmtprc

# Get Gmail credentials
echo ""
echo "To send emails via Gmail, you need an App Password:"
echo "1. Go to: https://myaccount.google.com/apppasswords"
echo "2. Generate an app password for 'Mail'"
echo "3. Copy the 16-character password"
echo ""
read -p "Enter your Gmail address: " GMAIL_USER
read -sp "Enter your Gmail App Password: " GMAIL_PASS
echo ""

# Create msmtp config
cat > ~/.msmtprc <<EOF
# Gmail SMTP configuration
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           $GMAIL_USER
user           $GMAIL_USER
password       $GMAIL_PASS
tls_starttls   on

account default : gmail
EOF

chmod 600 ~/.msmtprc

# Test email
echo ""
echo "Testing email configuration..."
echo "Test email from homelab health check" | msmtp grmojsoski@gmail.com

if [ $? -eq 0 ]; then
    echo "✅ Email test successful! Check your inbox."
else
    echo "❌ Email test failed. Check ~/.msmtp.log for details."
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Email notifications configured!"
echo "=========================================="
echo ""
echo "The health check script will now send emails to: grmojsoski@gmail.com"
echo "when critical issues are detected."
echo ""
echo "To test manually:"
echo "  echo 'Test message' | msmtp grmojsoski@gmail.com"
echo ""

