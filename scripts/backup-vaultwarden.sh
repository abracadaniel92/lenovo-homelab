#!/bin/bash
###############################################################################
# Vaultwarden Backup Script
# CRITICAL: This backs up your password vault!
###############################################################################

set -e

BACKUP_DIR="/mnt/ssd/backups/vaultwarden"
DATA_DIR="/mnt/ssd/docker-projects/vaultwarden/data"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/vaultwarden-${TIMESTAMP}.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "❌ ERROR: Data directory not found: $DATA_DIR"
    exit 1
fi

echo "🔐 Creating Vaultwarden backup..."
echo "   This includes your password vault database and keys"

# Stop Vaultwarden to ensure consistent backup
echo "   Stopping Vaultwarden..."
cd /mnt/ssd/docker-projects/vaultwarden
docker compose stop vaultwarden

# Create backup (exclude WAL files, they'll be recreated)
tar -czf "$BACKUP_FILE" \
    --exclude="*.sqlite3-shm" \
    --exclude="*.sqlite3-wal" \
    -C "$DATA_DIR" \
    . 2>/dev/null || {
    echo "❌ Backup failed!"
    docker compose start vaultwarden
    exit 1
}

# Start Vaultwarden
echo "   Starting Vaultwarden..."
docker compose start vaultwarden

# Set permissions
chmod 644 "$BACKUP_FILE"

# Get file size
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup created: $BACKUP_FILE ($FILE_SIZE)"

# Keep only last 30 backups
echo "🧹 Cleaning old backups (keeping last 30)..."
cd "$BACKUP_DIR"
ls -t vaultwarden-*.tar.gz 2>/dev/null | tail -n +31 | xargs -r rm -f

# Count remaining backups
BACKUP_COUNT=$(ls -1 vaultwarden-*.tar.gz 2>/dev/null | wc -l)
echo "📊 Total backups: $BACKUP_COUNT"

echo "✅ Backup complete!"
echo ""
echo "⚠️  IMPORTANT: Test restore this backup to ensure it works!"
echo "   Restore script: restore-vaultwarden.sh"


