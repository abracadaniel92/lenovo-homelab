#!/bin/bash
###############################################################################
# Format /dev/sda (1TB SATA SSD) as single ext4 partition and run SMART health check
# Run with: sudo bash scripts/format-and-healthcheck-1tb-ssd.sh
# WARNING: Destroys all data on /dev/sda
###############################################################################

set -e

DEV="${1:-/dev/sda}"
PART="${DEV}1"

echo "=== Target: $DEV (1TB SATA SSD) ==="
echo "WARNING: This will DESTROY all data on $DEV"
read -p "Type 'yes' to continue: " confirm
[[ "$confirm" == "yes" ]] || { echo "Aborted."; exit 1; }

# Unmount if mounted
if mountpoint -q "${DEV}1" 2>/dev/null || findmnt -n "$PART" &>/dev/null; then
    echo "Unmounting $PART..."
    umount "$PART" || true
fi

# Wipe and partition (GPT, single partition)
echo "Wiping and partitioning $DEV..."
wipefs -a "$DEV" 2>/dev/null || true
parted -s "$DEV" mklabel gpt
parted -s "$DEV" mkpart primary ext4 0% 100%
parted -s "$DEV" set 1 esp off

# Format
echo "Formatting ${PART} as ext4..."
mkfs.ext4 -F -L "ssd_1tb" "$PART"

# UUID for fstab
UUID=$(blkid -o value -s UUID "$PART")
echo ""
echo "=== Formatted. UUID: $UUID ==="
echo "To mount at boot, add to /etc/fstab:"
echo "  UUID=$UUID  /mnt/ssd_1tb  ext4  defaults,nofail  0  2"
echo "Then: sudo mkdir -p /mnt/ssd_1tb && sudo mount /mnt/ssd_1tb"
echo ""

# SMART health check
echo "=== SMART health check on $DEV ==="
if command -v smartctl &>/dev/null; then
    echo ""
    echo "--- Overall health ---"
    smartctl -H "$DEV" 2>/dev/null || smartctl -d sat -H "$DEV" 2>/dev/null || echo "SMART not available"
    echo ""
    echo "--- Key attributes ---"
    smartctl -A "$DEV" 2>/dev/null | grep -E "Reallocated|Pending|Offline_Uncorrectable|Power_On|Wear_Leveling|Health" || \
    smartctl -d sat -A "$DEV" 2>/dev/null | grep -E "Reallocated|Pending|Offline_Uncorrectable|Power_On|Wear_Leveling|Health" || true
else
    echo "Install smartmontools: sudo apt install smartmontools"
fi
echo ""
echo "Done."
