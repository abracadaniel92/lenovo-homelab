# Current Server Setup - December 31, 2025

## Architecture

```
Internet → Cloudflare → Cloudflare Tunnel (Docker, 2 replicas) → Caddy:8080 → Services
```

## Key Components

### Cloudflare Tunnel (Docker)
- **Location**: `/mnt/ssd/docker-projects/cloudflared/`
- **Replicas**: 2 (for redundancy)
- **Config**: `/home/goce/.cloudflared/config.yml`
- **Management**:
  ```bash
  cd /mnt/ssd/docker-projects/cloudflared
  docker compose ps          # Check status
  docker compose logs -f     # View logs
  docker compose restart     # Restart
  ```

### Caddy (Reverse Proxy)
- **Location**: `/mnt/ssd/docker-projects/caddy/`
- **Config**: Caddyfile in same directory
- **Repo config**: `Pi-version-control/docker/caddy/Caddyfile`
- **Port**: 8080 (HTTP, Cloudflare handles TLS)

### Health Check
- **Script**: `/usr/local/bin/enhanced-health-check.sh`
- **Timer**: `enhanced-health-check.timer` (every 30 seconds)
- **Log**: `/var/log/enhanced-health-check.log`
- **Checks**: Docker, Caddy, Tunnel, Nextcloud, Jellyfin, KitchenOwl, TravelSync, Planning Poker

### Uptime Kuma
- **URL**: http://localhost:3001
- **Notifications**: Configured (check Settings → Notifications)

## Important: Disabled Services

These were causing conflicts and are now DISABLED:

| Service | Status | Why |
|---------|--------|-----|
| `cloudflared.service` | REMOVED | Now using Docker |
| `service-watchdog.service` | DISABLED | Was conflicting |
| `service-health-check.timer` | DISABLED | Was conflicting |

**DO NOT re-enable these!**

## Quick Commands

### Check Everything
```bash
# Tunnel status
docker ps --filter "name=cloudflared"

# All services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Health check log
tail -20 /var/log/enhanced-health-check.log
```

### Fix Subdomains Down (502/404)
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
```

### Fix All Services
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```

### Sync Caddy Config from Repo
```bash
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/docker/caddy/Caddyfile" /mnt/ssd/docker-projects/caddy/
cd /mnt/ssd/docker-projects/caddy && docker compose restart caddy
```

## Services & Ports

| Service | Local Port | Domain |
|---------|------------|--------|
| Caddy | 8080 | All subdomains |
| Nextcloud | 8081 | cloud.gmojsoski.com |
| Vaultwarden | 8082 | vault.gmojsoski.com |
| GoatCounter | 8088 | analytics.gmojsoski.com |
| Gokapi | 8091 | files.gmojsoski.com |
| KitchenOwl | 8092 | shopping.gmojsoski.com |
| Jellyfin | 8096 | jellyfin.gmojsoski.com |
| TravelSync | 8000 | tickets.gmojsoski.com |
| Planning Poker | 3000 | poker.gmojsoski.com |
| Bookmarks | 5000 | bookmarks.gmojsoski.com |
| Uptime Kuma | 3001 | (internal only) |

## Troubleshooting

### Mobile Apps Not Working

1. **Force close app**
2. **Clear DNS cache**: Airplane mode ON/OFF
3. **Re-enter server URL** in app settings

### 502 Errors

Usually caching. Wait 1-2 minutes or:
```bash
cd /mnt/ssd/docker-projects/cloudflared && docker compose restart
cd /mnt/ssd/docker-projects/caddy && docker compose restart caddy
```

### Service Not Responding

```bash
# Check if container is running
docker ps | grep <service-name>

# Restart specific service
cd /mnt/ssd/docker-projects/<service> && docker compose restart
```

## Backups

Daily automated backups via cron:
- Nextcloud
- KitchenOwl  
- Vaultwarden
- TravelSync

Manual backup:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-all-critical.sh"
```

## What Changed Today (2025-12-31)

1. **Cloudflare Tunnel**: Moved from systemd to Docker with 2 replicas
2. **Removed conflicting services**: service-watchdog, service-health-check.timer
3. **Updated health check**: Now manages Docker tunnel instead of systemd
4. **Kuma notifications**: Configured
5. **Root cause found**: Multiple health checks were fighting each other

## For AI Assistant (Auto Mode)

When troubleshooting:
1. **Tunnel is Docker-based** - Don't try to restart `cloudflared.service`
2. **Only ONE health check** - `enhanced-health-check.timer`
3. **Caddyfile repo location**: `Pi-version-control/docker/caddy/Caddyfile`
4. **Cloudflared repo location**: `Pi-version-control/docker/cloudflared/`
5. **Fix scripts**: `Pi-version-control/restart services/`

Key directories:
- Docker projects: `/mnt/ssd/docker-projects/`
- Nextcloud: `/mnt/ssd/apps/nextcloud/`
- Cloudflared config: `/home/goce/.cloudflared/`




