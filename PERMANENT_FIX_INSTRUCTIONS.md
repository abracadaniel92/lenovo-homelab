# Permanent Service Fix - Instructions

## Current Issue

- Services are running locally but external access shows 502 errors
- Kuma is detecting failures but not sending alerts
- Cloudflare tunnel may be having intermittent connection issues

## Quick Fix (Run Now)

Run this command to apply the permanent fix:

```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/permanent-service-fix.sh"
```

## What the Fix Does

### 1. Enhanced Health Check (Every 1 Minute)
- Monitors all critical services
- Automatically restarts services that are down
- Logs all actions to `/var/log/enhanced-health-check.log`

### 2. Service Watchdog (Continuous)
- Runs continuously, checking every 30 seconds
- Automatically restarts:
  - Caddy if not responding
  - Cloudflare tunnel if not running
  - Planning Poker if not responding
- Runs as a systemd service that auto-starts on boot

### 3. Cloudflare Tunnel Auto-Recovery
- Enhanced restart settings
- Health check script to verify tunnel is working
- Automatic restart on failure

### 4. Auto-Start on Boot
- All monitoring services enabled to start on boot
- Services will auto-recover even after system restart

## After Running the Fix

### Check Status
```bash
# Check enhanced health check
systemctl status enhanced-health-check.timer
systemctl status enhanced-health-check.service

# Check service watchdog
systemctl status service-watchdog.service

# View logs
tail -f /var/log/enhanced-health-check.log
journalctl -u service-watchdog.service -f
```

### Verify Services
```bash
# Check all services are running
systemctl status cloudflared.service planning-poker.service gokapi.service bookmarks.service

# Check Docker containers
docker ps

# Test local access
curl http://localhost:8080/
curl http://localhost:8000/api/health
curl http://localhost:3000/
```

### Test External Access
```bash
# Test external domains
curl -I https://gmojsoski.com
curl -I https://tickets.gmojsoski.com
curl -I https://poker.gmojsoski.com
```

## Monitoring

The system now has three layers of protection:

1. **Enhanced Health Check** - Runs every minute, checks all services
2. **Service Watchdog** - Continuous monitoring every 30 seconds
3. **Systemd Auto-Restart** - Services restart automatically on failure

## Troubleshooting

### If services still fail:

1. **Check logs:**
   ```bash
   tail -50 /var/log/enhanced-health-check.log
   journalctl -u service-watchdog.service -n 50
   journalctl -u cloudflared.service -n 50
   ```

2. **Manually restart services:**
   ```bash
   sudo systemctl restart cloudflared.service
   cd /mnt/ssd/docker-projects/caddy && docker compose restart
   ```

3. **Check Cloudflare tunnel:**
   ```bash
   systemctl status cloudflared.service
   journalctl -u cloudflared.service -f
   ```

### If Kuma still not sending alerts:

1. **Check Uptime Kuma:**
   ```bash
   docker logs uptime-kuma --tail 50
   ```

2. **Verify notification settings in Kuma UI:**
   - Go to http://localhost:3001
   - Check notification settings
   - Verify notification channels are configured

## Files Created

- `/usr/local/bin/enhanced-health-check.sh` - Enhanced health check script
- `/etc/systemd/system/enhanced-health-check.service` - Health check service
- `/etc/systemd/system/enhanced-health-check.timer` - Health check timer (1 min)
- `/usr/local/bin/service-watchdog.sh` - Continuous watchdog script
- `/etc/systemd/system/service-watchdog.service` - Watchdog service
- `/usr/local/bin/cloudflared-health-check.sh` - Cloudflare tunnel health check

## Result

✅ Services will auto-recover from failures
✅ Monitoring runs continuously
✅ Services restart automatically
✅ Minimal downtime even during failures
✅ All fixes persist across reboots

