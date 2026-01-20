# Archived Scripts

This directory contains scripts that are no longer actively used but kept for reference.

## Archive Status

**Archive Cleaned**: January 2026

All one-time fix scripts, setup scripts, and obsolete scripts have been removed. Only scripts that might be useful for reference remain.

## Current Essential Scripts

All active scripts are in the parent `scripts/` directory:
- `enhanced-health-check.sh` - Main health check system
- `permanent-auto-recovery.sh` - Auto-recovery system
- `backup-*.sh` - All backup scripts
- `verify-*.sh` - Verification scripts
- `setup-*.sh` - Setup scripts
- `slack-goatcounter-weekly.sh` - Weekly analytics reports
- `slack-pi-monitoring.sh` - Pi monitoring reports

## Remaining Archived Scripts

### Reference Scripts
- `setup_xrdp.sh` - XRDP setup script (kept for reference)

## Archive Cleanup History

**January 2026**: Cleaned up archive by removing:
- **36+ one-time fix scripts** (already completed)
- **12+ one-time setup scripts** (already completed)
- **6+ obsolete scripts** (replaced or no longer needed)

All removed scripts were either:
- One-time fixes that were already applied
- Setup scripts that were already run
- Obsolete scripts replaced by better solutions

## Note

If you need any of the removed scripts, they can be restored from git history:
```bash
git log --all --full-history -- "scripts/archive/script-name.sh"
git checkout <commit-hash> -- "scripts/archive/script-name.sh"
```
