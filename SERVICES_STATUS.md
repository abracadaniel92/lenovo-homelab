# Services Status and Configuration

## Current System
- **Hardware**: Lenovo ThinkCentre
- **Architecture**: x86_64 (amd64)
- **OS**: Debian Linux

## All Services

### Docker Containers
| Service | Port | Domain | Status |
|---------|------|--------|--------|
| Caddy | 8080, 8443 | - | ✅ Running |
| GoatCounter | 8088 | analytics.gmojsoski.com | ✅ Running |
| Gokapi | 8091 | files.gmojsoski.com | ✅ Running |
| Nextcloud App | 8081 | cloud.gmojsoski.com | ✅ Running |
| Nextcloud DB | - | - | ✅ Running |
| Uptime Kuma | 3001 | - | ✅ Running |
| Documents-to-Calendar | 8000 | tickets.gmojsoski.com | ✅ Running |
| Pi-hole | 53 | - | ⚠️ Intermittent |

### Systemd Services
| Service | Port | Domain | Status |
|---------|------|--------|--------|
| Cloudflared | - | All domains | ✅ Running |
| Gokapi | 8091 | files.gmojsoski.com | ✅ Running |
| Bookmarks | 5000 | bookmarks.gmojsoski.com | ✅ Running |
| Planning Poker | 3000 | poker.gmojsoski.com | ✅ Running |

## Recent Fixes (December 2025)

### December 29, 2025
- **Planning Poker**: Fixed mobile browser issues (blank screen, downloading files) and bar chart alignment
- **TravelSync**: Fixed performance issues (reduced processing time from 48s to <10s), fixed "body is locked" errors, fixed format string errors, enabled best processing mode

## Recent Fixes (December 2025)

### Bookmarks Service
- **Issue**: Returning 404 for health checks
- **Fix**: Added health check route (`/`) to Flask app
- **File**: `/mnt/ssd/apps/bookmarks/secure_slack_bookmarks.py`
- **Status**: ✅ Fixed and working

### Planning Poker Service
- **Issue**: Service not running, causing 502 errors
- **Fix**: Created systemd service with nvm Node.js path
- **File**: `systemd/planning-poker.service`
- **Node Path**: `/home/goce/.nvm/versions/node/v20.19.6/bin/node`
- **Status**: ✅ Fixed and working

### Cloudflare Tunnel
- **Issue**: 502 Bad Gateway errors
- **Fix**: Fixed DNS configuration in Cloudflare dashboard
- **Status**: ✅ Fixed and working

### Health Check System
- **Interval**: Updated from 5 minutes to 2 minutes
- **Monitors**: All Docker containers and systemd services
- **Auto-restart**: Enabled for all services
- **Status**: ✅ Active and monitoring

### Poker Frontend
- **Issue**: CSS/JS files returning 404
- **Fix**: Added Host header forwarding in Caddy route
- **Status**: ✅ Fixed and working

### Nextcloud Routing
- **Issue**: 502 Bad Gateway via Caddy
- **Fix**: Changed from container hostname to host IP (172.17.0.1:8081)
- **Reason**: Caddy and Nextcloud on different Docker networks
- **Status**: ✅ Fixed and working

### Travelsync Route
- **Issue**: Domain not configured
- **Fix**: Added route to Caddyfile and Cloudflare config
- **Status**: ✅ Fixed and working

## Monitoring

### Uptime Kuma Monitors
- ✅ Caddy (Local) - `http://192.168.1.97:8080`
- ✅ Cloudflared Tunnel (Public) - `https://gmojsoski.com`
- ✅ GoatCounter - `https://analytics.gmojsoski.com`
- ✅ Gokapi - `https://files.gmojsoski.com`
- ✅ Bookmarks - `https://bookmarks.gmojsoski.com`
- ✅ Planning Poker - `https://poker.gmojsoski.com`
- ✅ Nextcloud - `https://cloud.gmojsoski.com`
- ✅ Documents-to-Calendar - `https://tickets.gmojsoski.com`

All monitors configured with Slack notifications.

## Service Locations

### Docker Projects
- `/mnt/ssd/docker-projects/caddy`
- `/mnt/ssd/docker-projects/goatcounter`
- `/mnt/ssd/docker-projects/uptime-kuma`
- `/mnt/ssd/docker-projects/pihole`
- `/mnt/ssd/docker-projects/documents-to-calendar`

### Applications
- `/mnt/ssd/apps/nextcloud`
- `/mnt/ssd/apps/gokapi`
- `/mnt/ssd/apps/bookmarks`
- `/home/goce/Desktop/Cursor projects/planning poker/planning_poker`

## Quick Commands

### Check All Services
```bash
# Docker containers
docker ps

# Systemd services
systemctl status cloudflared.service gokapi.service bookmarks.service planning-poker.service

# Health check status
systemctl status service-health-check.timer
```

### Restart All Services
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"
```

### View Health Check Logs
```bash
tail -f /var/log/service-health-check.log
```

