#!/bin/bash
###############################################################################
# Setup Automated Backups for All Critical Services
# Run with: sudo bash setup-all-backups-cron.sh
###############################################################################

if [ "$EUID" -ne 0 ]; then 
    echo "❌ This script must be run with sudo"
    echo "   Usage: sudo bash setup-all-backups-cron.sh"
    exit 1
fi

SCRIPT_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"

# Backup schedule: Daily at 2:00 AM
CRON_TIME="0 2"

# Check if cron jobs already exist
if grep -q "backup-all-critical.sh\|backup-vaultwarden.sh\|backup-nextcloud.sh\|backup-travelsync.sh\|backup-kitchenowl.sh" /etc/crontab; then
    echo "⚠️  Backup cron jobs already exist"
    echo "   Current entries:"
    grep -E "backup-(all-critical|vaultwarden|nextcloud|travelsync|kitchenowl)" /etc/crontab
    echo ""
    read -p "Replace them? (yes/no): " replace
    if [ "$replace" = "yes" ]; then
        # Remove old entries
        sed -i '/backup-\(all-critical\|vaultwarden\|nextcloud\|travelsync\|kitchenowl\)\.sh/d' /etc/crontab
        echo "✅ Removed old cron jobs"
    else
        echo "Cancelled."
        exit 0
    fi
fi

# Add comprehensive backup cron job (runs all critical backups)
echo "" >> /etc/crontab
echo "# Automated backups for all critical services - Daily at 2:00 AM" >> /etc/crontab
echo "$CRON_TIME * * * goce bash $SCRIPT_DIR/backup-all-critical.sh >> /var/log/backup-all-critical.log 2>&1" >> /etc/crontab

echo "✅ Automated backup cron job added!"
echo ""
echo "Schedule: Daily at 2:00 AM"
echo "Backs up: Vaultwarden, Nextcloud, TravelSync, KitchenOwl"
echo "Log file: /var/log/backup-all-critical.log"
echo ""
echo "To verify:"
echo "  grep backup /etc/crontab"
echo ""
echo "To test backup manually:"
echo "  bash $SCRIPT_DIR/backup-all-critical.sh"

