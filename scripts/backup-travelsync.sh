#!/bin/bash
###############################################################################
# TravelSync (Documents-to-Calendar) Backup Script
# Backs up travel data and calendar events database
###############################################################################

set -e

BACKUP_DIR="/mnt/ssd/backups/travelsync"
DATA_DIR="/mnt/ssd/docker-projects/documents-to-calendar/data"
DB_FILE="$DATA_DIR/documents_calendar.db"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/travelsync-${TIMESTAMP}.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if database file exists
if [ ! -f "$DB_FILE" ]; then
    echo "⚠️  WARNING: Database file not found: $DB_FILE"
    echo "   Creating backup of data directory anyway..."
fi

echo "✈️  Creating TravelSync backup..."
echo "   This includes travel data and calendar events"

# Create backup
tar -czf "$BACKUP_FILE" \
    -C "$DATA_DIR" \
    . 2>/dev/null || {
    echo "❌ Backup failed!"
    exit 1
}

# Set permissions
chmod 644 "$BACKUP_FILE"

# Get file size
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup created: $BACKUP_FILE ($FILE_SIZE)"

# Keep only last 30 backups
echo "🧹 Cleaning old backups (keeping last 30)..."
cd "$BACKUP_DIR"
ls -t travelsync-*.tar.gz 2>/dev/null | tail -n +31 | xargs -r rm -f

# Count remaining backups
BACKUP_COUNT=$(ls -1 travelsync-*.tar.gz 2>/dev/null | wc -l)
echo "📊 Total backups: $BACKUP_COUNT"

echo "✅ Backup complete!"



