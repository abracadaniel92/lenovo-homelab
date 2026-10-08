#!/bin/bash
# Replace the hand-copied /usr/local/bin scripts with symlinks into
# /opt/homelab/scripts, so they can never drift from the repo again.
# Run once on lemongrab: sudo /opt/homelab/scripts/link-usr-local-bin.sh
# Old copies are kept as <name>.sh.old. Safe to re-run.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }

for name in enhanced-health-check hdd-health-check sync-backups-to-b2 update-portfolio; do
    dst="/usr/local/bin/$name.sh"
    src="/opt/homelab/scripts/$name.sh"
    [ -f "$src" ] || { echo "MISSING $src, skipped"; continue; }
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "$dst.old"
    fi
    ln -sfn "$src" "$dst"
    echo "OK $dst -> $(readlink "$dst")"
done
