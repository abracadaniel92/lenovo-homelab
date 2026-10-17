#!/usr/bin/env bash
# Stop the Immich HDD (WD10SPZX, /mnt/ssd_1tb) parking its heads every ~2 min:
# 282k load cycles in 9.4k hours on 2026-10-17, rated ~600k.
# First run: applies APM 254 (now + on boot) and saves a baseline count.
# Later runs: show how much Load_Cycle_Count grew since the baseline.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

dev=$(printf "%s\n" /dev/disk/by-id/ata-WDC_WD10SPZX* | grep -v -- -part | head -1)
state=/var/lib/hdd-load-cycle.baseline
count() { smartctl -A "$dev" | awk '/Load_Cycle_Count/ {print $10}'; }

command -v hdparm >/dev/null || apt-get install -y hdparm
hdparm -B 254 "$dev"
grep -qF "$dev" /etc/hdparm.conf || printf '\n%s {\n\tapm = 254\n}\n' "$dev" >> /etc/hdparm.conf

now=$(count)
if [ -f "$state" ]; then
    read -r was since < "$state"
    echo "Load cycles: +$((now - was)) in $(( ($(date +%s) - since) / 60 )) min (before the fix: ~30/hour)"
else
    echo "$now $(date +%s)" > "$state"
    echo "Baseline saved: $now. Run this again in an hour."
fi
