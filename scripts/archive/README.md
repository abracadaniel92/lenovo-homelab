# Archived Scripts

This directory contains scripts that are no longer actively used but kept for reference.

## Why Archived?

These scripts were either:
- Replaced by more comprehensive scripts (e.g., `fix-all-services.sh`)
- One-time setup scripts that have already been run
- Obsolete fixes that are no longer needed
- Duplicate functionality

## Current Essential Scripts

All active scripts are in the parent `scripts/` directory:
- `fix-all-services.sh` - Main comprehensive service recovery
- `emergency-fix.sh` - Quick emergency recovery
- `fix-subdomains-down.sh` - Fix subdomain routing
- `backup-*.sh` - All backup scripts
- `setup-*.sh` - Setup scripts
- `permanent-auto-recovery.sh` - Auto-recovery system

## Archived Scripts

### Replaced Scripts
- `ensure-services-running.sh` - Replaced by `fix-all-services.sh`
- `quick-fix-all.sh` - Replaced by `fix-all-services.sh`
- `permanent-service-fix.sh` - Replaced by `permanent-auto-recovery.sh`
- `health-check-and-restart.sh` - Replaced by `permanent-auto-recovery.sh`

### Old Fix Scripts (No Longer Needed)
- `fix-bookmarks-poker.sh` - Old fix, no longer needed
- `fix-bookmarks-poker-complete.sh` - Old fix, no longer needed
- `fix-boot-startup-order.sh` - Replaced by `permanent-auto-recovery.sh`
- `fix-caddy-use-host-docker-internal.sh` - One-time fix, already done
- `fix-cloudflared-restart.sh` - Old fix, no longer needed
- `fix-cloudflared-tunnel.sh` - Old fix, no longer needed
- `fix-docker-restart-policies.sh` - One-time fix, already done
- `fix-health-check-service.sh` - One-time fix, already completed
- `fix-homepage-host-validation.sh` - Old fix, no longer needed
- `fix-poker-firewall.sh` - Old fix, no longer needed
- `fix-poker-gokapi-travelsync.sh` - Old fix, no longer needed
- `fix-slack.sh` - Old fix, no longer needed
- `fix-slack-services.sh` - Old fix, no longer needed
- `fix-slack-cgroup.sh` - Old fix, no longer needed
- `fix-ufw-docker-access.sh` - Old fix, no longer needed
- `fix-ufw-docker-complete.sh` - Old fix, no longer needed
- `fix-ufw-docker-integration.sh` - Old fix, no longer needed
- `fix-uptime-kuma-cloudflared-monitor.sh` - Old fix, no longer needed

### One-Time Setup Scripts (Already Run)
- `add-swap.sh` - One-time setup, already done
- `check-idle-status.sh` - One-time check script
- `configure-ufw-for-services.sh` - One-time setup, already done
- `install-filebrowser.sh` - One-time install, already done
- `install-homepage.sh` - One-time install, already done
- `install-useful-tools.sh` - One-time install, already done
- `install-watchtower.sh` - One-time install, already done
- `setup-fail2ban.sh` - One-time setup, already done
- `setup-portainer.sh` - One-time setup, already done
- `setup-slack-timers.sh` - One-time setup, already done
- `setup-uptime-kuma-cloudflared.sh` - One-time setup, already done
- `setup-uptime-kuma-monitors.sh` - One-time setup, already done
- `setup-uptime-kuma-services.sh` - One-time setup, already done
- `setup_xrdp.sh` - One-time setup, already done

### Obsolete Scripts
- `monitor-idle-continuous.sh` - No longer needed
- `optimize-fail2ban.sh` - One-time optimization, already done
- `optimize-system.sh` - One-time optimization, already done
- `slack-goatcounter-weekly.sh` - Obsolete
- `slack-pi-monitoring.sh` - Obsolete
- `start-slack.sh` - Obsolete
- `start-slack-workaround.sh` - Obsolete
- `update-health-check-interval.sh` - One-time update, already done

## Restore if Needed

If you need any of these scripts, you can restore them:
```bash
mv archive/script-name.sh ..
```

## Total Archived

**44 scripts archived** - Scripts directory reduced from 60 to 16 essential scripts.
