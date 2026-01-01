#!/bin/bash
###############################################################################
# Setup KitchenOwl Automated Backup Cron Job
# Run with: sudo bash setup-kitchenowl-backup-cron.sh
###############################################################################

if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run with sudo"
    echo "   Usage: sudo bash setup-kitchenowl-backup-cron.sh"
    exit 1
fi

CRON_LINE="0 2 * * * goce bash /home/goce/Desktop/Cursor\ projects/Pi-version-control/scripts/backup-kitchenowl.sh >> /var/log/kitchenowl-backup.log 2>&1"

# Check if cron job already exists
if grep -q "backup-kitchenowl.sh" /etc/crontab; then
    echo "⚠️  KitchenOwl backup cron job already exists"
    echo "   Current entry:"
    grep "backup-kitchenowl.sh" /etc/crontab
    echo ""
    read -p "Replace it? (yes/no): " replace
    if [ "$replace" = "yes" ]; then
        # Remove old entry
        sed -i '/backup-kitchenowl.sh/d' /etc/crontab
        echo "✅ Removed old cron job"
    else
        echo "Cancelled."
        exit 0
    fi
fi

# Add new cron job
echo "" >> /etc/crontab
echo "# KitchenOwl daily backup at 2 AM" >> /etc/crontab
echo "$CRON_LINE" >> /etc/crontab

echo "✅ KitchenOwl backup cron job added!"
echo ""
echo "Schedule: Daily at 2:00 AM"
echo "Backup location: /mnt/ssd/backups/kitchenowl/"
echo "Log file: /var/log/kitchenowl-backup.log"
echo ""
echo "To verify:"
echo "  grep kitchenowl /etc/crontab"
echo ""
echo "To test backup manually:"
echo "  bash /home/goce/Desktop/Cursor\\ projects/Pi-version-control/scripts/backup-kitchenowl.sh"





