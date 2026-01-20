#!/bin/bash
###############################################################################
# Fix Backup Cron Log Path
# Changes the backup cron job log path from /var/log/ to user-writable location
###############################################################################

set -e

echo "🔧 Fixing backup cron job log path..."
echo ""

# Backup original crontab
echo "📋 Backing up /etc/crontab..."
sudo cp /etc/crontab /etc/crontab.backup.$(date +%Y%m%d-%H%M%S)
echo "   ✅ Backup created"

# Check if log directory exists
LOG_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control/logs"
mkdir -p "$LOG_DIR"
echo "   ✅ Log directory exists: $LOG_DIR"

# Update crontab entry
echo ""
echo "🔧 Updating crontab entry..."
OLD_LOG="/var/log/backup-all-critical.log"
NEW_LOG="$LOG_DIR/backup-all-critical.log"

# Replace the log path in crontab
sudo sed -i "s|$OLD_LOG|$NEW_LOG|g" /etc/crontab

echo "   ✅ Updated: $OLD_LOG → $NEW_LOG"

# Verify change
echo ""
echo "📋 Verifying crontab entry:"
grep "backup-all-critical" /etc/crontab || echo "   ⚠️  WARNING: Crontab entry not found!"

echo ""
echo "✅ Fix complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Cron will automatically reload the new crontab"
echo "   2. Next backup will run at 2:00 AM and log to: $NEW_LOG"
echo "   3. Check logs after next backup: tail -f $NEW_LOG"



