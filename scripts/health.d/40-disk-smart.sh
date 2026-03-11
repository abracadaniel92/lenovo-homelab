#!/bin/bash
# 40-disk-smart.sh: SMART health check for USB-attached HDDs (docking stations)
# Requires: smartmontools (apt install smartmontools)
# Detects disks from mount points /mnt/disk1, /mnt/disk2, /mnt/disk_old

if ! command -v smartctl &>/dev/null; then
    log "SKIP: smartctl not found. Install with: sudo apt install smartmontools"
    return 0
fi

# Mount points: primary 1TB SATA SSD + USB HDDs (from homelab storage setup)
USB_DISK_MOUNTS=( "/mnt/ssd_1tb" "/mnt/disk1" "/mnt/disk2" "/mnt/disk_old" )

# Get block device for a mount point (e.g. /mnt/disk1 -> /dev/sdb1), then parent disk (/dev/sdb)
get_disk_for_mount() {
    local mount_point="$1"
    local src
    src=$(findmnt -n -o SOURCE "$mount_point" 2>/dev/null)
    if [ -z "$src" ]; then
        echo ""
        return
    fi
    # If SOURCE is /dev/sdb1, we want /dev/sdb (strip trailing digit(s))
    if [[ "$src" =~ ^/dev/sd[a-z][0-9]+$ ]]; then
        echo "${src%%[0-9]*}"
    else
        echo "$src"
    fi
}

# Run smartctl; try default then -d sat for USB bridges
smartctl_health() {
    local dev="$1"
    local out
    out=$(smartctl -H "$dev" 2>&1)
    if echo "$out" | grep -qi "unknown usb bridge\|unsupported.*usb"; then
        out=$(smartctl -d sat -H "$dev" 2>&1)
    fi
    echo "$out"
}

smartctl_attributes() {
    local dev="$1"
    local out
    out=$(smartctl -A "$dev" 2>&1)
    if echo "$out" | grep -qi "unknown usb bridge\|unsupported.*usb"; then
        out=$(smartctl -d sat -A "$dev" 2>&1)
    fi
    echo "$out"
}

# Parse SMART raw value for an attribute (last column in smartctl -A output)
get_smart_attr() {
    local attrs_out="$1"
    local name="$2"
    echo "$attrs_out" | awk -v name="$name" '
        $0 ~ name { gsub(/^0+/, "", $NF); print $NF; exit }
    '
}

# Get disk space summary for a mount point (e.g. "77G used, 1.7T free")
get_mount_space() {
    local mount_point="$1"
    if ! findmnt -n "$mount_point" &>/dev/null; then
        echo "not mounted"
        return
    fi
    local used avail
    used=$(df -h "$mount_point" 2>/dev/null | tail -1 | awk '{print $3}')
    avail=$(df -h "$mount_point" 2>/dev/null | tail -1 | awk '{print $4}')
    echo "${used:-?} used, ${avail:-?} free"
}

# Check one disk; returns 0 if OK, 1 if failed. Sets DISK_STATUS_MSG for summary.
check_one_disk() {
    local mount_point="$1"
    local label="$2"
    local space_info
    space_info=$(get_mount_space "$mount_point")

    local dev
    dev=$(get_disk_for_mount "$mount_point")
    if [ -z "$dev" ]; then
        log "DISK SMART: $label ($mount_point) not mounted — skipping"
        DISK_STATUS_MSG+=("• **$label** ($mount_point): not mounted")
        return 0
    fi
    if [ ! -b "$dev" ]; then
        log "DISK SMART: $label device $dev not found — skipping"
        DISK_STATUS_MSG+=("• **$label** ($mount_point): device not found")
        return 0
    fi

    local health_out
    health_out=$(smartctl_health "$dev")
    if echo "$health_out" | grep -q "SMART overall-health self-assessment test result: FAILED"; then
        log "CRITICAL: HDD SMART health FAILED — $label ($dev)"
        send_slack_notification "🚨 HDD SMART FAILED" "Drive **$label** ($dev) reports SMART overall health: **FAILED**. Consider backing up and replacing soon." "🚨"
        DISK_STATUS_MSG+=("• **$label** ($mount_point): ❌ SMART FAILED — $space_info")
        return 1
    fi
    if ! echo "$health_out" | grep -q "PASSED"; then
        if echo "$health_out" | grep -qi "unsupported\|cannot read\|failed to open"; then
            log "DISK SMART: $label ($dev) — SMART not supported by USB bridge (enclosure may not pass SMART)"
            DISK_STATUS_MSG+=("• **$label** ($mount_point): SMART N/A (USB bridge) — $space_info")
            return 0
        fi
        log "WARNING: HDD SMART $label ($dev) — could not determine health: $health_out"
        DISK_STATUS_MSG+=("• **$label** ($mount_point): unknown — $space_info")
        return 0
    fi

    local attrs_out
    attrs_out=$(smartctl_attributes "$dev")
    local realloc pending offline
    realloc=$(get_smart_attr "$attrs_out" "Reallocated_Sector_Ct")
    pending=$(get_smart_attr "$attrs_out" "Current_Pending_Sector")
    offline=$(get_smart_attr "$attrs_out" "Offline_Uncorrectable")
    realloc=${realloc:-0}
    pending=${pending:-0}
    offline=${offline:-0}

    if [ "$realloc" -gt 0 ] 2>/dev/null || [ "$pending" -gt 0 ] 2>/dev/null || [ "$offline" -gt 0 ] 2>/dev/null; then
        log "WARNING: HDD SMART pre-failure signs — $label ($dev) Realloc=$realloc Pending=$pending Offline_Uncorrectable=$offline"
        send_slack_notification "⚠️ HDD Pre-failure signs" "Drive **$label** ($dev): Reallocated sectors=$realloc, Pending=$pending, Offline uncorrectable=$offline. Plan backup/replacement." "⚠️"
        DISK_STATUS_MSG+=("• **$label** ($mount_point): ⚠️ pre-failure signs — $space_info")
        return 1
    fi

    log "DISK SMART: $label ($dev) — health PASSED, no bad sectors — $space_info"
    DISK_STATUS_MSG+=("• **$label** ($mount_point): ✅ OK — $space_info")
    return 0
}

# Run checks for each configured USB disk and send one summary if all checked
DISK_STATUS_MSG=()
for mount_point in "${USB_DISK_MOUNTS[@]}"; do
    label=$(basename "$mount_point")
    check_one_disk "$mount_point" "$label"
done

# Send summary notification only on Sunday 11am, once (first run in that hour; failures/warnings sent immediately above)
day=$(date +%u)    # 1=Mon .. 7=Sun
hour=$(date +%H)
minute=$(date +%M)
if [ "${day}" = "7" ] && [ "${hour}" = "11" ] && [ "${minute}" -lt 5 ] 2>/dev/null && [ ${#DISK_STATUS_MSG[@]} -gt 0 ]; then
    summary=$(IFS=$'\n'; echo "${DISK_STATUS_MSG[*]}")
    send_slack_notification "💾 USB HDDs health" "$summary" "💾"
fi
