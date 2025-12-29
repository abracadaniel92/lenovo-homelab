# Repository Cleanup Recommendations

**Date**: December 29, 2025

## Overview

This document identifies files in the root directory that are outdated, one-time use, or no longer relevant to current operations.

## Files Recommended for Removal or Archival

### 1. **GEODE_EVALUATION.md** ❌ Remove
- **Reason**: Evaluation of AMD Geode processor that was decided not to use
- **Status**: System is already on Lenovo ThinkCentre, evaluation is complete
- **Action**: Delete - no longer relevant

### 2. **WHAT_I_DID.md** ⚠️ Archive or Remove
- **Reason**: One-time explanation of service outage from December 28, 2025
- **Status**: Historical context, emergency is resolved
- **Action**: Can be removed or moved to `archive/` folder if you want to keep historical records

### 3. **CONFIGURATION_AUDIT.md** ⚠️ Archive or Remove
- **Reason**: One-time configuration audit snapshot from December 28, 2025
- **Status**: Issues mentioned were likely fixed, audit is outdated
- **Action**: Can be removed or archived - current status is in `SERVICES_STATUS.md` and `CHANGELOG.md`

### 4. **EMERGENCY_RESTORE.md** ⚠️ Archive or Remove
- **Reason**: One-time emergency procedure from December 28, 2025
- **Status**: Emergency resolved, procedures are in other docs
- **Action**: Can be removed - emergency procedures are documented in `CHANGELOG.md` and scripts

### 5. **IDLE_CHECK_RESULTS.md** ⚠️ Archive or Remove
- **Reason**: One-time diagnostic results from a specific date
- **Status**: Issues mentioned (health check, swap) were likely fixed
- **Action**: Can be removed - diagnostic info is outdated

### 6. **MIGRATION_GUIDE.md** ⚠️ Keep for Reference
- **Reason**: Detailed migration guide from Pi to ThinkCentre
- **Status**: Migration is complete, but could be useful for future migrations
- **Action**: **Keep** - useful reference if you ever need to migrate again

### 7. **QUICK_MIGRATION.md** ⚠️ Keep for Reference
- **Reason**: Quick reference for migration process
- **Status**: Migration complete, but useful as reference
- **Action**: **Keep** - complements MIGRATION_GUIDE.md

### 8. **BACKUP_SUMMARY.md** ⚠️ Archive or Remove
- **Reason**: One-time backup summary from December 19, 2024
- **Status**: Historical record of completed backup
- **Action**: Can be removed or archived - backup is complete

### 9. **backup_pi.sh** ⚠️ Keep if You Have Another Pi
- **Reason**: Script to backup FROM Raspberry Pi
- **Status**: You're on ThinkCentre now, but might have other Pis
- **Action**: **Keep** if you have other Pis, otherwise can be removed

### 10. **restore_to_thinkcentre.sh** ⚠️ Archive or Remove
- **Reason**: Script to restore TO ThinkCentre
- **Status**: Restore is complete, unlikely to need again
- **Action**: Can be removed or archived - restore is done

## Files to Keep (Active/Useful)

✅ **CHANGELOG.md** - Active documentation of all changes
✅ **README.md** - Main documentation
✅ **SERVICES_STATUS.md** - Current service status
✅ **STABILITY_FIXES.md** - Active stability documentation
✅ All fix documentation (POKER_*.md, CLOUDFLARED_*.md, etc.) - Useful references
✅ All setup guides (FAIL2BAN_*.md, DOCKER_UI_SETUP.md, etc.) - Still relevant
✅ All scripts in `scripts/` - Actively used
✅ All systemd files - Active configurations
✅ All docker configs - Active configurations

## Recommended Actions

### Option 1: Clean Removal (Recommended)
Remove files that are clearly outdated:
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
rm GEODE_EVALUATION.md
rm WHAT_I_DID.md
rm CONFIGURATION_AUDIT.md
rm EMERGENCY_RESTORE.md
rm IDLE_CHECK_RESULTS.md
rm BACKUP_SUMMARY.md
rm restore_to_thinkcentre.sh  # If restore is complete
```

### Option 2: Archive for History
Create an `archive/` folder and move historical files:
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
mkdir -p archive/2024 archive/2025
mv GEODE_EVALUATION.md archive/
mv WHAT_I_DID.md archive/2025/
mv CONFIGURATION_AUDIT.md archive/2025/
mv EMERGENCY_RESTORE.md archive/2025/
mv IDLE_CHECK_RESULTS.md archive/2025/
mv BACKUP_SUMMARY.md archive/2024/
mv restore_to_thinkcentre.sh archive/2024/
```

### Option 3: Keep Everything
If you prefer to keep all historical records, no action needed.

## Summary

**Definitely Remove:**
- `GEODE_EVALUATION.md` - No longer relevant

**Consider Removing/Archiving:**
- `WHAT_I_DID.md` - One-time explanation
- `CONFIGURATION_AUDIT.md` - Outdated snapshot
- `EMERGENCY_RESTORE.md` - One-time emergency
- `IDLE_CHECK_RESULTS.md` - Outdated diagnostic
- `BACKUP_SUMMARY.md` - Historical record
- `restore_to_thinkcentre.sh` - Migration complete

**Keep:**
- `MIGRATION_GUIDE.md` - Useful reference
- `QUICK_MIGRATION.md` - Useful reference
- `backup_pi.sh` - Keep if you have other Pis

## Impact

Removing these files will:
- ✅ Clean up root directory (reduce clutter)
- ✅ Make it easier to find active documentation
- ✅ Remove confusion about which docs are current
- ✅ Keep repository focused on active operations

No negative impact - all important information is already in:
- `CHANGELOG.md` (comprehensive change history)
- `SERVICES_STATUS.md` (current status)
- `README.md` (main documentation)
- Individual fix documentation files

