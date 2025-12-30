#!/bin/bash
###############################################################################
# Nextcloud Backup Script
# Backs up database and important config files
###############################################################################

set -e

BACKUP_DIR="/mnt/ssd/backups/nextcloud"
NEXTCLOUD_DIR="/mnt/ssd/apps/nextcloud"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/nextcloud-${TIMESTAMP}.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "☁️  Creating Nextcloud backup..."
echo "   This includes database dump and config files"

# Backup PostgreSQL database
echo "   Dumping database..."
DB_BACKUP="/tmp/nextcloud-db-${TIMESTAMP}.sql"
docker exec nextcloud-postgres pg_dump -U nextcloud nextcloud > "$DB_BACKUP" || {
    echo "❌ Database dump failed!"
    exit 1
}

# Backup config files
echo "   Backing up config files..."
CONFIG_BACKUP="/tmp/nextcloud-config-${TIMESTAMP}.tar.gz"
tar -czf "$CONFIG_BACKUP" \
    -C "$NEXTCLOUD_DIR/app/config" \
    config.php 2>/dev/null || echo "⚠️  Config backup skipped (file may not exist)"

# Create combined backup
echo "   Creating backup archive..."
tar -czf "$BACKUP_FILE" \
    -C /tmp \
    "nextcloud-db-${TIMESTAMP}.sql" \
    "nextcloud-config-${TIMESTAMP}.tar.gz" 2>/dev/null || {
    echo "❌ Backup archive creation failed!"
    rm -f "$DB_BACKUP" "$CONFIG_BACKUP"
    exit 1
}

# Cleanup temp files
rm -f "$DB_BACKUP" "$CONFIG_BACKUP"

# Set permissions
chmod 644 "$BACKUP_FILE"

# Get file size
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup created: $BACKUP_FILE ($FILE_SIZE)"

# Keep only last 30 backups
echo "🧹 Cleaning old backups (keeping last 30)..."
cd "$BACKUP_DIR"
ls -t nextcloud-*.tar.gz 2>/dev/null | tail -n +31 | xargs -r rm -f

# Count remaining backups
BACKUP_COUNT=$(ls -1 nextcloud-*.tar.gz 2>/dev/null | wc -l)
echo "📊 Total backups: $BACKUP_COUNT"

echo "✅ Backup complete!"
echo ""
echo "ℹ️  Note: User files are in /mnt/ssd/apps/nextcloud/app/data/"
echo "   Consider backing up that directory separately if needed."

