# Monitoring and Auto-Recovery System

This document describes the monitoring and auto-recovery system implemented on the Lenovo ThinkCentre server.

## Overview

The server has a multi-layer monitoring system that ensures services stay online:

| Layer | Tool | Frequency | Purpose |
|-------|------|-----------|---------|
| 1 | enhanced-health-check.timer | Every 30 seconds | Check & restart all services |
| 2 | service-watchdog.service | Continuous (20s loop) | Monitor critical services |
| 3 | Uptime Kuma | Every 60 seconds | External monitoring & alerts |
| 4 | Docker restart policies | On failure | Auto-restart containers |

## Active Monitoring Services

### 1. Enhanced Health Check Timer

**Service**: `enhanced-health-check.timer`  
**Script**: `/usr/local/bin/enhanced-health-check.sh`  
**Frequency**: Every 30 seconds  
**Log**: `/var/log/enhanced-health-check.log`

**Services Monitored**:
- Docker daemon
- Caddy (reverse proxy) - CRITICAL
- Cloudflare Tunnel
- TravelSync (documents-to-calendar)
- Planning Poker
- Nextcloud
- Jellyfin
- KitchenOwl
- Gokapi
- Bookmarks

**Check Status**:
```bash
systemctl status enhanced-health-check.timer
tail -50 /var/log/enhanced-health-check.log
```

### 2. Service Watchdog

**Service**: `service-watchdog.service`  
**Script**: `/usr/local/bin/service-watchdog.sh`  
**Frequency**: Continuous (20 second intervals)  

**Services Monitored**:
- Caddy
- Cloudflare Tunnel
- Planning Poker

**Check Status**:
```bash
systemctl status service-watchdog.service
```

### 3. Uptime Kuma

**URL**: http://localhost:3001 (internal only)  
**Container**: uptime-kuma  
**Location**: `/mnt/ssd/docker-projects/uptime-kuma`

**Monitors All Services**:
- All public endpoints (https://*)
- Internal services
- Sends alerts on downtime

**⚠️ IMPORTANT**: Uptime Kuma notifications must be configured manually:
1. Go to http://localhost:3001
2. Settings → Notifications
3. Add notification method (Telegram, Email, Slack, etc.)
4. Apply to all monitors

## Recovery Scripts

### Quick Fix (Everything Down)

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```

This comprehensive script:
- ✅ Fixes UDP buffer sizes (Cloudflare tunnel stability)
- ✅ Starts Docker if stopped
- ✅ Starts Caddy first (critical)
- ✅ Starts all Docker containers
- ✅ Starts all systemd services
- ✅ Tests connectivity
- ✅ Shows status

### Emergency Fix (Faster)

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/emergency-fix.sh"
```

### Subdomain Fix (502/404 Errors)

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
```

## Startup Order

After boot, services start in this order:

1. **Docker daemon** (systemd)
2. **Docker containers** (docker restart policies)
3. **Caddy** (CRITICAL - must be first Docker container)
4. **Cloudflare Tunnel** (cloudflared.service)
5. **Other services** (systemd services, remaining containers)

## Common Issues and Fixes

### Issue: All subdomains return 502/404

**Cause**: Cloudflare tunnel or Caddy not running  
**Fix**:
```bash
sudo systemctl restart cloudflared.service
docker restart caddy
```

### Issue: Services work locally but not externally

**Cause**: Cloudflare tunnel disconnected  
**Fix**:
```bash
sudo systemctl restart cloudflared.service
# Wait 1-2 minutes for reconnection
```

### Issue: Specific service not responding

**Fix**:
```bash
# For Docker containers
docker restart <container-name>

# For systemd services
sudo systemctl restart <service-name>
```

### Issue: Services go down after reboot

**Cause**: Startup order issues or race conditions  
**Fix**: Run the permanent auto-recovery script (once):
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/permanent-auto-recovery.sh"
```

## Network Architecture

```
Internet
    │
    ▼
Cloudflare (TLS termination)
    │
    ▼
Cloudflare Tunnel (cloudflared:8080)
    │
    ▼
Caddy (localhost:8080)
    │
    ├─► gmojsoski.com → Static files
    ├─► cloud.gmojsoski.com → 172.17.0.1:8081 (Nextcloud)
    ├─► files.gmojsoski.com → 172.17.0.1:8091 (Gokapi)
    ├─► shopping.gmojsoski.com → 172.17.0.1:8092 (KitchenOwl)
    ├─► jellyfin.gmojsoski.com → 172.17.0.1:8096 (Jellyfin)
    ├─► poker.gmojsoski.com → 172.17.0.1:3000 (Planning Poker)
    ├─► tickets.gmojsoski.com → 172.17.0.1:8000 (TravelSync)
    ├─► vault.gmojsoski.com → 172.17.0.1:8082 (Vaultwarden)
    └─► ...more services
```

## Backup System

### Automated Backups

**Schedule**: Daily at 2:00 AM  
**Cron Entry**: `/etc/crontab`

```bash
0 2 * * * goce bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-all-critical.sh"
```

**Services Backed Up**:
- Vaultwarden (passwords) - `/mnt/ssd/backups/vaultwarden/`
- Nextcloud (files & DB) - `/mnt/ssd/backups/nextcloud/`
- TravelSync (travel data) - `/mnt/ssd/backups/travelsync/`
- KitchenOwl (shopping lists) - `/mnt/ssd/backups/kitchenowl/`

**Retention**: Last 30 backups per service

### Manual Backup

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-all-critical.sh"
```

## Health Check Logs

View recent health checks:
```bash
tail -100 /var/log/enhanced-health-check.log
```

## Troubleshooting Checklist

When services are down:

1. **Check if Docker is running**
   ```bash
   docker ps
   ```

2. **Check Caddy container**
   ```bash
   docker ps | grep caddy
   curl http://localhost:8080
   ```

3. **Check Cloudflare tunnel**
   ```bash
   systemctl status cloudflared.service
   journalctl -u cloudflared.service -n 30 --no-pager
   ```

4. **Run the fix script**
   ```bash
   bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
   ```

5. **Check health logs**
   ```bash
   tail -50 /var/log/enhanced-health-check.log
   ```

## Prevention Measures

To prevent downtime:

1. **UDP Buffer Sizes** - Prevents Cloudflare tunnel instability
   ```bash
   # Already in /etc/sysctl.conf
   net.core.rmem_max=8388608
   net.core.rmem_default=8388608
   ```

2. **Docker Restart Policies** - All containers have `restart: always`

3. **Health Checks** - Running every 30 seconds

4. **Service Watchdog** - Continuous monitoring

5. **Daily Backups** - Prevent data loss

## Last Updated

December 31, 2025

