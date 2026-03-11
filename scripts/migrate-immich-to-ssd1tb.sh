#!/bin/bash
###############################################################################
# Migrate Immich library from mergerfs (/mnt/storage/immich-library) to
# primary 1TB SSD (/mnt/ssd_1tb/immich-library). Run on server with Immich.
# Usage: sudo bash scripts/migrate-immich-to-ssd1tb.sh
###############################################################################

set -e

OLD_LOCATION="${1:-/mnt/storage/immich-library}"
NEW_LOCATION="${2:-/mnt/ssd_1tb/immich-library}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMMICH_DIR="${IMMICH_DIR:-$REPO_DIR/docker/immich}"

echo "=== Immich migration to 1TB SSD (primary storage) ==="
echo "  From: $OLD_LOCATION"
echo "  To:   $NEW_LOCATION"
echo "  Immich compose: $IMMICH_DIR"
echo ""

# 1. Ensure new location is mounted
if ! mountpoint -q "$(dirname "$NEW_LOCATION")" 2>/dev/null; then
    echo "ERROR: $(dirname "$NEW_LOCATION") is not mounted. Mount the 1TB SSD first, e.g.:"
    echo "  sudo mkdir -p $(dirname "$NEW_LOCATION") && sudo mount /dev/sda1 $(dirname "$NEW_LOCATION")"
    echo "  (Add to /etc/fstab for boot - use UUID from: sudo blkid /dev/sda1)"
    exit 1
fi

# 2. Stop Immich
echo "Stopping Immich..."
cd "$IMMICH_DIR"
docker compose stop immich-server immich-machine-learning 2>/dev/null || true
# Keep DB and Redis running so we don't lose state

# 3. Create destination and sync
echo "Creating $NEW_LOCATION and syncing data..."
mkdir -p "$NEW_LOCATION"
if [ -d "$OLD_LOCATION" ] && [ "$(ls -A "$OLD_LOCATION" 2>/dev/null)" ]; then
    rsync -av --progress "$OLD_LOCATION"/ "$NEW_LOCATION"/
else
    echo "Source empty or missing; creating Immich library structure..."
    for dir in upload library thumbs encoded-video profile backups; do
        mkdir -p "$NEW_LOCATION/$dir"
        touch "$NEW_LOCATION/$dir/.immich"
    done
fi

# 4. Update .env
ENV_FILE="$IMMICH_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    if grep -q "^UPLOAD_LOCATION=" "$ENV_FILE"; then
        sed -i "s|^UPLOAD_LOCATION=.*|UPLOAD_LOCATION=$NEW_LOCATION|" "$ENV_FILE"
        echo "Updated UPLOAD_LOCATION in $ENV_FILE"
    else
        echo "UPLOAD_LOCATION=$NEW_LOCATION" >> "$ENV_FILE"
    fi
else
    echo "WARNING: .env not found at $ENV_FILE; set UPLOAD_LOCATION=$NEW_LOCATION manually"
fi

# 5. Start Immich
echo "Starting Immich..."
docker compose up -d

echo ""
echo "Done. Immich now uses $NEW_LOCATION (1TB SSD) as primary storage."
echo "Verify at https://immich.gmojsoski.com (or your Immich URL)."
echo "Old data remains at $OLD_LOCATION; you can remove it after confirming everything works."
