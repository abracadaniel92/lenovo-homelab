#!/usr/bin/env bash
# migrate-containerd-to-home.sh
# Migrates /var/lib/containerd (~76GB) from root partition to /home/containerd
# to free space on root (currently at 98%).
#
# Strategy: rsync data, then symlink so containerd finds it at the original path.
# Old data is kept as /var/lib/containerd.old until manual removal.
#
# Usage: sudo bash scripts/migrate-containerd-to-home.sh

set -euo pipefail

SRC="/var/lib/containerd"
DST="/home/containerd"
BACKUP="${SRC}.old"

echo "============================================="
echo "  Containerd Storage Migration"
echo "  ${SRC} → ${DST}"
echo "============================================="
echo ""

# --- Pre-flight checks ---

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Must be run as root (sudo)."
    exit 1
fi

if [ -L "${SRC}" ]; then
    echo "ERROR: ${SRC} is already a symlink. Migration may have already been done."
    echo "  Current target: $(readlink -f "${SRC}")"
    exit 1
fi

if [ -d "${DST}" ]; then
    echo "ERROR: Destination ${DST} already exists. Aborting to avoid data loss."
    exit 1
fi

# Check source exists
if [ ! -d "${SRC}" ]; then
    echo "ERROR: Source ${SRC} does not exist."
    exit 1
fi

# Check /home has enough space
SRC_SIZE_KB=$(du -sx "${SRC}" 2>/dev/null | awk '{print $1}')
HOME_AVAIL_KB=$(df --output=avail /home | tail -1 | tr -d ' ')

echo "Source size:       $(numfmt --to=iec --from-unit=1024 "${SRC_SIZE_KB}")"
echo "Available on /home: $(numfmt --to=iec --from-unit=1024 "${HOME_AVAIL_KB}")"
echo ""

if [ "${SRC_SIZE_KB}" -gt "${HOME_AVAIL_KB}" ]; then
    echo "ERROR: Not enough space on /home!"
    exit 1
fi

echo "This will:"
echo "  1. Stop docker and containerd"
echo "  2. rsync ${SRC}/ → ${DST}/"
echo "  3. Rename ${SRC} → ${BACKUP}"
echo "  4. Symlink ${SRC} → ${DST}"
echo "  5. Start containerd and docker"
echo ""
echo "Old data will be kept at ${BACKUP} until you remove it manually."
echo ""
read -rp "Proceed? [y/N] " confirm
if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# --- Step 1: Stop services ---
echo ""
echo "[1/5] Stopping docker and containerd..."
systemctl stop docker docker.socket containerd || true
sleep 2

# Verify nothing is using the source
if lsof +D "${SRC}" >/dev/null 2>&1; then
    echo "WARNING: Processes still using ${SRC}. Listing:"
    lsof +D "${SRC}" 2>/dev/null || true
    echo ""
    read -rp "Continue anyway? [y/N] " force
    if [[ ! "${force}" =~ ^[Yy]$ ]]; then
        echo "Aborted. Restarting services..."
        systemctl start containerd docker
        exit 1
    fi
fi

# --- Step 2: rsync ---
echo ""
echo "[2/5] Syncing data (this may take a while for ~$(numfmt --to=iec --from-unit=1024 "${SRC_SIZE_KB}"))..."
rsync -aHAXx --progress "${SRC}/" "${DST}/"
echo "Sync complete."

# --- Step 3: Rename old directory ---
echo ""
echo "[3/5] Renaming ${SRC} → ${BACKUP}..."
mv "${SRC}" "${BACKUP}"

# --- Step 4: Create symlink ---
echo ""
echo "[4/5] Creating symlink ${SRC} → ${DST}..."
ln -s "${DST}" "${SRC}"
echo "Symlink created: $(ls -la "${SRC}")"

# --- Step 5: Start services ---
echo ""
echo "[5/5] Starting containerd and docker..."
systemctl start containerd
sleep 3
systemctl start docker
sleep 3

# --- Verification ---
echo ""
echo "============================================="
echo "  Verification"
echo "============================================="
echo ""

echo "Symlink:"
ls -la "${SRC}"
echo ""

echo "Docker status:"
if systemctl is-active --quiet docker; then
    echo "  docker: RUNNING ✅"
else
    echo "  docker: FAILED ❌"
fi

if systemctl is-active --quiet containerd; then
    echo "  containerd: RUNNING ✅"
else
    echo "  containerd: FAILED ❌"
fi

echo ""
echo "Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null | head -20 || echo "  (could not list containers)"

echo ""
echo "Disk usage:"
df -h / /home | column -t
echo ""
echo "New location size:"
du -shx "${DST}" 2>/dev/null

echo ""
echo "============================================="
echo "  Migration complete!"
echo "  Old data at: ${BACKUP}"
echo "  Remove it ONLY after confirming everything works:"
echo "    sudo rm -rf ${BACKUP}"
echo "============================================="
