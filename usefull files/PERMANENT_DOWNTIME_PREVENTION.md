# Permanent Downtime Prevention

## Problem

Services keep going down, requiring manual intervention. We need a permanent solution that automatically detects and fixes issues.

## Solution: Permanent Auto-Recovery System

### Quick Setup (Run Once)

```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/permanent-auto-recovery.sh"
```

This sets up:
1. **Enhanced Health Check** - Runs every 30 seconds
2. **Service Watchdog** - Continuous monitoring every 20 seconds
3. **Auto-Restart** - Services automatically restart on failure
4. **Boot Protection** - Services auto-start on system restart

## How It Works

### 1. Enhanced Health Check (Every 30 Seconds)

- Checks all critical services
- Automatically restarts services that are down
- Logs all actions to `/var/log/enhanced-health-check.log`
- Runs as systemd timer

### 2. Service Watchdog (Continuous)

- Runs continuously, checking every 20 seconds
- Monitors:
  - Caddy (reverse proxy)
  - Cloudflare Tunnel
  - Planning Poker
- Auto-restarts on failure
- Runs as systemd service

### 3. Auto-Start on Boot

- All Docker containers: `restart: always`
- All systemd services: `Restart=always`
- Monitoring services: Enabled to start on boot

## What Gets Monitored

### Critical Services (Auto-Restart):
- **Caddy** - Reverse proxy (if down, everything fails)
- **Cloudflare Tunnel** - External access (if down, no public access)
- **TravelSync** - Document processing
- **Planning Poker** - Planning app
- **Nextcloud** - Cloud storage
- **Gokapi** - File sharing
- **Bookmarks** - Bookmarks service

## Monitoring Commands

### Check Monitoring Status
```bash
# Check health check timer
systemctl status enhanced-health-check.timer

# Check watchdog service
systemctl status service-watchdog.service

# View health check logs
tail -f /var/log/enhanced-health-check.log

# View watchdog logs
journalctl -u service-watchdog.service -f
```

### Manual Health Check
```bash
# Run health check manually
sudo /usr/local/bin/enhanced-health-check.sh
```

## Response Times

- **Health Check**: Detects issues within 30 seconds
- **Watchdog**: Detects issues within 20 seconds
- **Auto-Restart**: Services restart within 5-10 seconds
- **Total Recovery Time**: ~30-60 seconds maximum

## Boot Protection

On system restart:
1. Docker starts automatically
2. Docker containers start (with `restart: always`)
3. Systemd services start (with `Restart=always`)
4. Monitoring services start after 1 minute
5. Services auto-recover if they fail during boot

## Troubleshooting

### If services still go down:

1. **Check monitoring is running:**
   ```bash
   systemctl status enhanced-health-check.timer
   systemctl status service-watchdog.service
   ```

2. **Check logs:**
   ```bash
   tail -50 /var/log/enhanced-health-check.log
   journalctl -u service-watchdog.service -n 50
   ```

3. **Manually restart services:**
   ```bash
   bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/quick-fix-all.sh"
   ```

4. **Check Docker:**
   ```bash
   systemctl status docker
   docker ps
   ```

### If monitoring services fail:

```bash
# Restart monitoring
sudo systemctl restart enhanced-health-check.timer
sudo systemctl restart service-watchdog.service

# Re-enable if disabled
sudo systemctl enable enhanced-health-check.timer
sudo systemctl enable service-watchdog.service
```

## Files Created

- `/usr/local/bin/enhanced-health-check.sh` - Health check script
- `/etc/systemd/system/enhanced-health-check.service` - Health check service
- `/etc/systemd/system/enhanced-health-check.timer` - Health check timer (30s)
- `/usr/local/bin/service-watchdog.sh` - Watchdog script
- `/etc/systemd/system/service-watchdog.service` - Watchdog service
- `/var/log/enhanced-health-check.log` - Health check logs

## Result

✅ **Services auto-recover from failures**
✅ **Monitoring runs continuously**
✅ **Services restart automatically**
✅ **Minimal downtime (30-60 seconds max)**
✅ **All fixes persist across reboots**
✅ **No manual intervention needed**

## Quick Fix from Phone

If you need to manually fix everything:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/quick-fix-all.sh"
```

But with the permanent system in place, this should rarely be needed!

