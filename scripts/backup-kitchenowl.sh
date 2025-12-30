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

# Keep only last 30 backups (remove oldest)
echo "🧹 Cleaning old backups (keeping last 30)..."
cd "$BACKUP_DIR"
ls -t kitchenowl-*.db 2>/dev/null | tail -n +31 | xargs -r rm -f

# Count remaining backups
BACKUP_COUNT=$(ls -1 kitchenowl-*.db 2>/dev/null | wc -l)
echo "📊 Total backups: $BACKUP_COUNT"

echo "✅ Backup complete!"


