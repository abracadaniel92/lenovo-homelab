# All Prevention and Recovery Scripts

Complete reference for all scripts that prevent and fix downtime.

## 📍 Script Locations

**Main Directory**: `/home/goce/Desktop/Cursor projects/Pi-version-control/`

## 🚨 Emergency Fix Scripts

Located in: `restart services/`

### 1. **fix-all-services.sh** ⭐ RECOMMENDED
**Purpose**: Comprehensive service recovery - fixes everything
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```
**What it does**:
- ✅ Fixes UDP buffer sizes (Cloudflare tunnel stability)
- ✅ Starts Docker if stopped
- ✅ Starts Caddy first (critical - reverse proxy)
- ✅ Starts all Docker containers
- ✅ Starts all systemd services
- ✅ Tests local connectivity
- ✅ Shows status

**When to use**: Everything is down, or services are unstable

### 2. **emergency-fix.sh**
**Purpose**: Quick emergency recovery
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/emergency-fix.sh"
```
**When to use**: Need a quick fix, less comprehensive

### 3. **fix-subdomains-down.sh**
**Purpose**: Fix subdomain routing issues (502/404 errors)
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
```
**What it does**:
- ✅ Restarts Caddy (reverse proxy)
- ✅ Restarts Cloudflare Tunnel
- ✅ Tests local connectivity
- ✅ Tests external access
- ✅ Shows status and logs

**When to use**: Subdomains return 502/404 but services work locally

### 4. **fix-downtime-issues.sh**
**Purpose**: Permanent fixes for downtime issues
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-downtime-issues.sh"
```
**What it does**:
- ✅ Sets UDP buffer sizes permanently
- ✅ Enables service watchdog timer
- ✅ Restarts Cloudflare tunnel

**When to use**: After downtime, to prevent it from happening again

### 5. **diagnose-502.sh**
**Purpose**: Diagnose 502 errors
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/diagnose-502.sh"
```

### 6. **fix-502-external-access.sh**
**Purpose**: Fix 502 errors from external networks
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-502-external-access.sh"
```

## 🛡️ Monitoring & Auto-Recovery Scripts

Located in: `scripts/`

### 1. **permanent-auto-recovery.sh** ⭐ SETUP ONCE
**Purpose**: Set up permanent monitoring and auto-recovery
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/permanent-auto-recovery.sh"
```
**What it sets up**:
- ✅ Enhanced health check (runs every 30 seconds)
- ✅ Service watchdog (continuous, checks every 20 seconds)
- ✅ Auto-restart on failures
- ✅ Boot protection

**When to use**: Run ONCE to set up permanent monitoring

### 2. **enhanced-health-check.sh**
**Purpose**: Health check script (installed to `/usr/local/bin/`)
**Location**: `/usr/local/bin/enhanced-health-check.sh`
**Runs**: Every 30 seconds via `enhanced-health-check.timer`

**Monitors**:
- Docker daemon
- Caddy (reverse proxy) - CRITICAL
- Cloudflare Tunnel
- TravelSync
- Planning Poker
- Nextcloud
- Jellyfin
- KitchenOwl
- Vaultwarden
- Gokapi
- Bookmarks

**Log**: `/var/log/enhanced-health-check.log`

## 🔄 Systemd Services & Timers

### Active Monitoring

1. **enhanced-health-check.timer**
   - **Frequency**: Every 30 seconds
   - **Status**: `systemctl status enhanced-health-check.timer`
   - **Logs**: `tail -f /var/log/enhanced-health-check.log`

2. **service-watchdog.service**
   - **Frequency**: Continuous (20 second intervals)
   - **Status**: `systemctl status service-watchdog.service`
   - **Script**: `/usr/local/bin/service-watchdog.sh`

3. **cloudflared.service**
   - **Purpose**: Cloudflare tunnel (external access)
   - **Status**: `systemctl status cloudflared.service`
   - **Logs**: `journalctl -u cloudflared.service -f`

### Check Status

```bash
# Check all monitoring services
systemctl status enhanced-health-check.timer service-watchdog.service cloudflared.service

# Check if they're active
systemctl is-active enhanced-health-check.timer
systemctl is-active service-watchdog.service
systemctl is-active cloudflared.service
```

## 📋 Quick Reference

### Everything Down?
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```

### Subdomains Down (502/404)?
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
```

### Check Monitoring Status?
```bash
systemctl status enhanced-health-check.timer service-watchdog.service
tail -50 /var/log/enhanced-health-check.log
```

### Setup Permanent Monitoring?
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/permanent-auto-recovery.sh"
```

## 📁 File Locations Summary

| Script | Location | Purpose |
|--------|----------|---------|
| fix-all-services.sh | `restart services/` | Comprehensive fix |
| emergency-fix.sh | `restart services/` | Quick fix |
| fix-subdomains-down.sh | `restart services/` | Fix 502/404 |
| fix-downtime-issues.sh | `restart services/` | Permanent fixes |
| permanent-auto-recovery.sh | `scripts/` | Setup monitoring |
| enhanced-health-check.sh | `/usr/local/bin/` | Health check |
| service-watchdog.sh | `/usr/local/bin/` | Continuous monitoring |

## 🔍 Troubleshooting

### Monitoring Not Working?

1. **Check if services are active**:
   ```bash
   systemctl is-active enhanced-health-check.timer
   systemctl is-active service-watchdog.service
   ```

2. **Check logs**:
   ```bash
   tail -100 /var/log/enhanced-health-check.log
   journalctl -u service-watchdog.service -n 50
   ```

3. **Restart monitoring**:
   ```bash
   sudo systemctl restart enhanced-health-check.timer
   sudo systemctl restart service-watchdog.service
   ```

### Services Still Going Down?

1. **Run comprehensive fix**:
   ```bash
   bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
   ```

2. **Setup permanent fixes**:
   ```bash
   bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-downtime-issues.sh"
   ```

3. **Verify monitoring is active**:
   ```bash
   systemctl status enhanced-health-check.timer service-watchdog.service
   ```

## 📚 Related Documentation

- `MONITORING_AND_RECOVERY.md` - Comprehensive monitoring guide
- `QUICK_SSH_COMMANDS.md` - Quick reference for phone SSH
- `EMERGENCY_RESTORE.md` - Emergency restore procedures

## 🎯 Most Important Scripts

1. **fix-all-services.sh** - Use when everything is down
2. **permanent-auto-recovery.sh** - Run once to set up monitoring
3. **fix-subdomains-down.sh** - Use when subdomains are 502/404

