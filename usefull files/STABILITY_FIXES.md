# System Stability and Auto-Restart Fixes

This document describes the fixes applied to resolve machine freezes, Cloudflare error 1033, and ensure all services run continuously.

## Issues Fixed

1. **Cloudflare Error 1033**: Fixed Cloudflare tunnel configuration
2. **Docker Restart Policies**: Changed all containers from `unless-stopped` to `always` for maximum reliability
3. **Systemd Services**: Updated cloudflared service to use `Restart=always` instead of `on-failure`
4. **Auto-Start Configuration**: Created scripts to ensure all services start on boot
5. **Health Monitoring**: Added automated health checks that run every 2 minutes (updated from 5 minutes)
6. **Bookmarks Service**: Added health check route (`/`) to Flask app for monitoring
7. **Planning Poker Service**: Created systemd service with proper Node.js path (nvm support)

## Changes Made

### 1. Docker Compose Files
All Docker compose files now use `restart: always`:
- `docker/caddy/docker-compose.yml`
- `docker/nextcloud/docker-compose.yml`
- `docker/goatcounter/docker-compose.yml`
- `docker/uptime-kuma/docker-compose.yml`
- `docker/pihole/docker-compose.yml`
- `docker/documents-to-calendar/docker-compose.yml`

### 2. Systemd Services
- `systemd/cloudflared.service`: Changed to `Restart=always` with `StartLimitInterval=0`
- `systemd/bookmarks.service`: Already configured with `Restart=always`
- `systemd/planning-poker.service`: Created with `Restart=always`, uses nvm Node.js path

### 3. Cloudflare Configuration
- `cloudflare/config.yml`: Added tickets.gmojsoski.com entry and improved comments

### 4. New Scripts Created

#### `scripts/optimize-system.sh`
Comprehensive system optimization script that:
- Enables Docker and all systemd services
- Configures systemd failure handling
- Optimizes kernel parameters for stability
- Configures log rotation
- Sets up automated health checks
- Increases file descriptor limits
- Configures Docker for auto-restart

**Run this once to set up everything:**
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/optimize-system.sh"
```

#### `scripts/health-check-and-restart.sh`
Automated health check that:
- Monitors all Docker containers
- Monitors all systemd services
- Restarts any stopped services
- Checks port connectivity
- Monitors system resources (memory, disk)
- Logs all activity to `/var/log/service-health-check.log`

**This runs automatically every 2 minutes via systemd timer (updated for faster detection).**

#### `scripts/ensure-services-running.sh`
Quick script to manually start all services:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"
```

## How to Apply the Fixes

### Step 1: Run the Optimization Script
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/optimize-system.sh"
```

This will:
- Configure all services to auto-start
- Set up health monitoring
- Optimize system parameters
- Start all services

### Step 2: Verify Services Are Running
```bash
# Check Docker containers
docker ps

# Check systemd services
systemctl status cloudflared.service
systemctl status gokapi.service
systemctl status bookmarks.service

# Check health check timer
systemctl status service-health-check.timer
```

### Step 3: Monitor Health Check Logs
```bash
# View recent health check logs
tail -f /var/log/service-health-check.log

# Check health check status
systemctl status service-health-check.timer
journalctl -u service-health-check.service -f
```

## Service Ports Reference

| Service | Port | Domain |
|---------|------|--------|
| Caddy (HTTP) | 8080 | - |
| Caddy (HTTPS) | 8443 | - |
| Nextcloud | 8081 | cloud.gmojsoski.com |
| GoatCounter | 8088 | analytics.gmojsoski.com |
| Gokapi | 8091 | files.gmojsoski.com |
| Bookmarks | 5000 | bookmarks.gmojsoski.com |
| Planning Poker | 3000 | poker.gmojsoski.com |
| Documents-to-Calendar | 8000 | tickets.gmojsoski.com |
| Uptime Kuma | 3001 | - |

## Troubleshooting

### If services still stop:
1. Check health check logs: `tail -f /var/log/service-health-check.log`
2. Check Docker logs: `docker logs <container-name>`
3. Check systemd logs: `journalctl -u <service-name> -f`
4. Manually restart: `bash scripts/ensure-services-running.sh`

### If machine still freezes:
1. Check system resources: `htop` or `free -h`
2. Check disk space: `df -h`
3. Review kernel logs: `dmesg | tail -50`
4. Consider disabling swap (commented in optimize-system.sh)

### Cloudflare Error 1033:
1. Verify cloudflared is running: `systemctl status cloudflared.service`
2. Check Cloudflare config: `cat ~/.cloudflared/config.yml`
3. Restart cloudflared: `systemctl restart cloudflared.service`
4. Check Cloudflare logs: `journalctl -u cloudflared.service -f`

### Nextcloud 502 Bad Gateway:
1. Check if Nextcloud is running: `docker ps | grep nextcloud`
2. Verify Nextcloud is accessible directly: `curl http://localhost:8081`
3. **Common Issue**: Caddy and Nextcloud on different Docker networks
   - **Fix**: Use host IP in Caddyfile: `http://172.17.0.1:8081` instead of `http://nextcloud-app:80`
   - Check networks: `docker inspect caddy --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}'`
   - Check Nextcloud network: `docker inspect nextcloud-app --format '{{range $net, $conf := .NetworkSettings.Networks}}{{$net}} {{end}}'`

### Poker Frontend Not Loading (CSS/JS 404):
1. Check Caddy route has Host header forwarding:
   ```caddy
   reverse_proxy http://172.17.0.1:3000 {
       header_up Host {host}
       header_up X-Forwarded-Host {host}
   }
   ```
2. Verify static files accessible directly: `curl http://localhost:3000/style.css`
3. Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`

## Auto-Start Services

The following services are now configured to auto-start on boot:

**Docker Containers:**
- caddy
- goatcounter
- uptime-kuma
- nextcloud-app
- nextcloud-postgres
- pihole
- documents-to-calendar

**Systemd Services:**
- cloudflared.service
- gokapi.service
- bookmarks.service
- planning-poker.service
- service-health-check.timer

## Recent Fixes (December 2025)

### Bookmarks Service Fix
- **Issue**: Service was returning 404 for health checks
- **Fix**: Added health check route (`/`) to Flask app that returns `{"status": "ok", "service": "bookmarks"}`
- **File**: `/mnt/ssd/apps/bookmarks/secure_slack_bookmarks.py`
- **Result**: Service now responds correctly to health checks and Uptime Kuma monitoring

### Planning Poker Service Setup
- **Issue**: Service was not running, causing 502 Bad Gateway errors
- **Fix**: Created systemd service file with proper Node.js path (nvm support)
- **File**: `systemd/planning-poker.service`
- **Note**: Uses Node.js from nvm at `/home/goce/.nvm/versions/node/v20.19.6/bin/node`
- **Result**: Service now auto-starts on boot and restarts on failure

### Cloudflare Tunnel Fix
- **Issue**: Tunnel was connected but not forwarding requests (502 errors)
- **Fix**: Fixed DNS configuration in Cloudflare dashboard to point to tunnel
- **Result**: All services now accessible through public endpoints

### Health Check Interval Update
- **Change**: Reduced health check interval from 5 minutes to 2 minutes
- **Reason**: Faster detection of service failures
- **Script**: `scripts/update-health-check-interval.sh`

## Maintenance

The health check runs automatically every 2 minutes. No manual intervention needed unless you see errors in the logs.

To manually trigger a health check:
```bash
sudo systemctl start service-health-check.service
```

To view what the health check does:
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/health-check-and-restart.sh"
```













