#!/bin/bash
###############################################################################
# Backup All Critical Services
# Runs backups for all critical services in one command
###############################################################################

# Deliberately NOT `set -e`. This loop previously aborted on the first failing
# service, and Vaultwarden is first in the list, so one bad Vaultwarden run
# silently skipped the four services after it. Each service is now independent
# and the script exits non-zero if ANY of them failed, which is what lets
# systemd's OnFailure= notifier fire.
set -uo pipefail

# Derived rather than hardcoded: the repo path contains a space, and a literal
# unquoted path is exactly what broke the backup cron for eight months.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Backing up all critical services..."
echo ""

# Services to backup (in order)
SERVICES=("vaultwarden" "nextcloud" "travelsync" "kitchenowl" "linkwarden")

failed=()
for service in "${SERVICES[@]}"; do
    echo "🔄 Processing $service..."
    if bash "$SCRIPT_DIR/backup-engine.sh" "$service"; then
        echo ""
    else
        echo "❌ $service backup FAILED (continuing with remaining services)"
        echo ""
        failed+=("$service")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    echo "❌ ${#failed[@]} of ${#SERVICES[@]} backups failed: ${failed[*]}"
    exit 1
fi

echo "✅ All critical services backed up!"
echo ""
echo "📦 Backup locations:"
echo "   Vaultwarden: /mnt/ssd/backups/vaultwarden/"
echo "   Nextcloud:  /mnt/ssd/backups/nextcloud/"
echo "   TravelSync: /mnt/ssd/backups/travelsync/"
echo "   KitchenOwl: /mnt/ssd/backups/kitchenowl/"
echo "   Linkwarden: /mnt/ssd/backups/linkwarden/"
