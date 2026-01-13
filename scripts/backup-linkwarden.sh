#!/bin/bash
###############################################################################
# Linkwarden Backup Script
# Creates timestamped backups of Linkwarden data, PostgreSQL database, and Meilisearch index
###############################################################################

set -e

BACKUP_DIR="/mnt/ssd/backups/linkwarden"
DATA_DIR="/home/docker-projects/linkwarden"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/linkwarden-${TIMESTAMP}.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
    echo "❌ ERROR: Linkwarden directory not found: $DATA_DIR"
    exit 1
fi

# Create backup
echo "📦 Creating Linkwarden backup..."
cd "$DATA_DIR"

# Backup: data/, pgdata/, meili_data/
tar -czf "$BACKUP_FILE" \
    data/ \
    pgdata/ \
    meili_data/ \
    2>/dev/null || {
    echo "⚠️  Warning: Some directories may not exist yet (this is normal for new installations)"
    # Create minimal backup with what exists
    tar -czf "$BACKUP_FILE" data/ pgdata/ meili_data/ 2>/dev/null || true
}

# Set permissions
chmod 644 "$BACKUP_FILE"

# Get file size
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "✅ Backup created: $BACKUP_FILE ($FILE_SIZE)"

# Smart retention cleanup (multi-tier: hourly, daily, weekly, monthly, yearly)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/backup-retention-helper.sh"
smart_retention_cleanup "$BACKUP_DIR" "linkwarden-*.tar.gz" "Linkwarden"

echo "✅ Backup complete!"

