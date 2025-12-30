#!/bin/bash
###############################################################################
# Backup All Critical Services
# Runs backups for all critical services in one command
###############################################################################

set -e

SCRIPT_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"

echo "🔄 Backing up all critical services..."
echo ""

# Vaultwarden (CRITICAL - passwords)
echo "1️⃣  Vaultwarden (Password Vault)..."
bash "$SCRIPT_DIR/backup-vaultwarden.sh"
echo ""

# Nextcloud (CRITICAL - user files and database)
echo "2️⃣  Nextcloud (User Files & Database)..."
bash "$SCRIPT_DIR/backup-nextcloud.sh"
echo ""

# TravelSync (IMPORTANT - travel data)
echo "3️⃣  TravelSync (Travel Data)..."
bash "$SCRIPT_DIR/backup-travelsync.sh"
echo ""

# KitchenOwl (IMPORTANT - shopping lists)
echo "4️⃣  KitchenOwl (Shopping Lists)..."
bash "$SCRIPT_DIR/backup-kitchenowl.sh"
echo ""

echo "✅ All critical services backed up!"
echo ""
echo "📦 Backup locations:"
echo "   Vaultwarden: /mnt/ssd/backups/vaultwarden/"
echo "   Nextcloud:  /mnt/ssd/backups/nextcloud/"
echo "   TravelSync: /mnt/ssd/backups/travelsync/"
echo "   KitchenOwl: /mnt/ssd/backups/kitchenowl/"

