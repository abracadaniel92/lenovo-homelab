#!/bin/bash
###############################################################################
# KitchenOwl Database Restore Script
# Restores KitchenOwl database from backup
###############################################################################

set -e

BACKUP_DIR="/mnt/ssd/backups/kitchenowl"
DATA_DIR="/mnt/ssd/docker-projects/kitchenowl/data"
DB_FILE="$DATA_DIR/kitchenowl.db"

# List available backups
echo "📦 Available KitchenOwl backups:"
echo ""
ls -lh "$BACKUP_DIR"/kitchenowl-*.db 2>/dev/null | awk '{print NR, $9, $5, $6, $7, $8}' || {
    echo "❌ No backups found in $BACKUP_DIR"
    exit 1
}

echo ""
read -p "Enter backup number to restore (or 'q' to quit): " choice

if [ "$choice" = "q" ] || [ -z "$choice" ]; then
    echo "Cancelled."
    exit 0
fi

# Get backup file
BACKUP_FILE=$(ls -t "$BACKUP_DIR"/kitchenowl-*.db 2>/dev/null | sed -n "${choice}p")

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Invalid backup number"
    exit 1
fi

echo ""
echo "⚠️  WARNING: This will replace the current database!"
echo "   Backup: $BACKUP_FILE"
echo "   Target: $DB_FILE"
echo ""
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Stop KitchenOwl
echo "🛑 Stopping KitchenOwl..."
cd /mnt/ssd/docker-projects/kitchenowl
docker compose stop kitchenowl

# Backup current database (just in case)
if [ -f "$DB_FILE" ]; then
    CURRENT_BACKUP="$BACKUP_DIR/kitchenowl-pre-restore-$(date +%Y%m%d-%H%M%S).db"
    cp "$DB_FILE" "$CURRENT_BACKUP"
    echo "💾 Current database backed up to: $CURRENT_BACKUP"
fi

# Restore backup
echo "📥 Restoring backup..."
cp "$BACKUP_FILE" "$DB_FILE"
chmod 644 "$DB_FILE"
chown goce:goce "$DB_FILE" 2>/dev/null || echo "⚠️  Note: May need to fix permissions manually with: sudo chown goce:goce $DB_FILE"

# Start KitchenOwl
echo "▶️  Starting KitchenOwl..."
docker compose start kitchenowl

sleep 3

# Verify
if docker ps | grep -q kitchenowl; then
    echo "✅ KitchenOwl restarted successfully!"
    echo ""
    echo "📋 Restored from: $BACKUP_FILE"
    echo "🌐 Check: https://shopping.gmojsoski.com"
else
    echo "❌ ERROR: KitchenOwl failed to start. Check logs:"
    echo "   docker logs kitchenowl"
    exit 1
fi

