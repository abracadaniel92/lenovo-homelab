#!/bin/bash
###############################################################################
# Backup All Critical Services
# Runs backups for all critical services in one command
###############################################################################

set -e

SCRIPT_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"

echo "🔄 Backing up all critical services..."
echo ""

# Services to backup (in order)
SERVICES=("vaultwarden" "nextcloud" "travelsync" "kitchenowl" "linkwarden")

for service in "${SERVICES[@]}"; do
    echo "🔄 Processing $service..."
    bash "$SCRIPT_DIR/backup-engine.sh" "$service"
    echo ""
done

echo "✅ All critical services backed up!"
echo ""
echo "📦 Backup locations:"
echo "   Vaultwarden: /mnt/ssd/backups/vaultwarden/"
echo "   Nextcloud:  /mnt/ssd/backups/nextcloud/"
echo "   TravelSync: /mnt/ssd/backups/travelsync/"
echo "   KitchenOwl: /mnt/ssd/backups/kitchenowl/"
echo "   Linkwarden: /mnt/ssd/backups/linkwarden/"





