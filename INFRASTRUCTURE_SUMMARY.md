# Infrastructure Summary - January 2026

## Server Details
- **Hostname**: lemongrab
- **OS**: Linux (Debian-based)
- **Storage**: 512GB NVMe SSD
  - `/` (root): 102GB partition
  - `/home`: 374GB partition (docker data lives here)
- **Docker data location**: `/home/docker-projects/` (symlinked from `/mnt/ssd/docker-projects/`)

## Running Services (15 containers)

| Service | Port | External URL | Notes |
|---------|------|--------------|-------|
| **Caddy** | 8080 | - | Reverse proxy for all services |
| **Cloudflare Tunnel** | - | - | 2 replicas for redundancy |
| **Jellyfin** | 8096 | jellyfin.gmojsoski.com | Media server (movies, TV, music, books) |
| **KitchenOwl** | 8092 | shopping.gmojsoski.com | Recipe manager (294 recipes imported) |
| **Vaultwarden** | 8082 | vault.gmojsoski.com | Password manager |
| **Nextcloud** | 8081 | cloud.gmojsoski.com | Cloud storage (PostgreSQL backend) |
| **Uptime Kuma** | 3001 | - | Monitoring |
| **GoatCounter** | 8088 | analytics.gmojsoski.com | Web analytics |
| **Homepage** | 8000 | - | Dashboard |
| **Portainer** | 9000 | - | Docker management UI |
| **Gokapi** | 8091 | files.gmojsoski.com | File sharing |
| **Documents-to-Calendar** | - | - | Custom app |
| **Watchtower** | - | - | Auto-updates (daily 2 AM) |
| **Nginx (Vaultwarden)** | 8083 | - | DELETE→PUT rewrite for iOS |

## Systemd Services
- **Planning Poker**: `planning-poker.service`
- **Bookmarks**: `bookmarks.service`
- **Gokapi**: `gokapi.service`

## Key Configuration Files

### Docker Compose Locations
```
/home/docker-projects/caddy/docker-compose.yml
/home/docker-projects/cloudflared/docker-compose.yml
/home/docker-projects/jellyfin/docker-compose.yml
/home/docker-projects/kitchenowl/docker-compose.yml
/home/docker-projects/vaultwarden/docker-compose.yml
/home/docker-projects/uptime-kuma/docker-compose.yml
/home/docker-projects/goatcounter/docker-compose.yml
/home/docker-projects/watchtower/docker-compose.yml
/home/apps/nextcloud/docker-compose.yml
```

### Caddyfile
```
/home/docker-projects/caddy/config/Caddyfile
```

### Health Check
```
/usr/local/bin/enhanced-health-check.sh
```
- Runs every 30 seconds via `enhanced-health-check.timer`
- Auto-restarts failed services
- Logs to `/var/log/enhanced-health-check.log`

## Watchtower Configuration
- **Schedule**: Daily at 2:00 AM UTC
- **Excluded from auto-updates** (manual only):
  - Nextcloud
  - Vaultwarden
  - Jellyfin
  - KitchenOwl

## Slack Notifications
- **Weekly Analytics**: Sundays 10 AM (`slack-goatcounter-weekly.timer`)
- **Scripts location**: `/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/`

## Common Commands

### Restart a service
```bash
cd /home/docker-projects/<service>
docker compose restart
```

### Check all containers
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Check health check logs
```bash
tail -50 /var/log/enhanced-health-check.log
```

### Restart Cloudflare tunnel
```bash
cd /home/docker-projects/cloudflared && docker compose restart
```

### Check external access
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://jellyfin.gmojsoski.com
```

## KitchenOwl Recipe Import
- **294 recipes** imported from Word documents
- Source files: `~/Downloads/drive-download-20251231T155334Z-1-001/`
- Import script: `/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/import-recipes-to-kitchenowl.py`
- Database: `/home/docker-projects/kitchenowl/data/database.db`

## Backup Locations
- Scripts: `/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/`
- Backups: `/mnt/ssd/backups/`

## Git Repository
- **Local**: `/home/goce/Desktop/Cursor projects/Pi-version-control/`
- **Remote**: https://github.com/abracadaniel92/lenovo-version-control

## Recent Changes (Jan 2026)
1. Removed Kavita (replaced by Jellyfin for books)
2. Removed Umami & Plausible analytics
3. Enabled Watchtower with exclusions
4. Moved docker data from root to /home (339GB free)
5. Fixed KitchenOwl and imported 294 recipes
6. Updated Slack notification scripts
7. Cleaned up duplicate health checks
8. Fixed Vaultwarden iOS DELETE method issue (via Nginx proxy)

## Troubleshooting

### Services not accessible externally
1. Check Cloudflare tunnel: `docker logs cloudflared-cloudflared-1`
2. Restart tunnel: `cd /home/docker-projects/cloudflared && docker compose restart`
3. Check Caddy: `docker logs caddy`

### Container keeps restarting
1. Check logs: `docker logs <container-name>`
2. Check health: `docker inspect <container-name> --format '{{.State.Health}}'`

### Database locked errors
1. Stop container first: `docker compose stop`
2. Make changes
3. Restart: `docker compose up -d`

