#!/bin/bash
###############################################################################
# KitchenOwl Database Backup Script
# Creates timestamped backups of KitchenOwl database
###############################################################################

set -e

BACKUP_DIR="/mnt/ssd/backups/kitchenowl"
DATA_DIR="/mnt/ssd/docker-projects/kitchenowl/data"
DB_FILE="$DATA_DIR/kitchenowl.db"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/kitchenowl-${TIMESTAMP}.db"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if database file exists
if [ ! -f "$DB_FILE" ]; then
    echo "❌ ERROR: Database file not found: $DB_FILE"
    exit 1
fi

# Create backup
echo "📦 Creating KitchenOwl backup..."
cp "$DB_FILE" "$BACKUP_FILE"

# Set permissions
chmod 644 "$BACKUP_FILE"

# Get file size
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup created: $BACKUP_FILE ($FILE_SIZE)"

# Smart retention cleanup (multi-tier: hourly, daily, weekly, monthly, yearly)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/backup-retention-helper.sh"
smart_retention_cleanup "$BACKUP_DIR" "kitchenowl-*.db" "KitchenOwl"

echo "✅ Backup complete!"





