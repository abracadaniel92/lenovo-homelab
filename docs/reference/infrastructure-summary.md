# Infrastructure Summary - January 2026

Quick reference for the lemongrab server.

## Server Details

| Detail | Value |
|--------|-------|
| **Hostname** | lemongrab |
| **OS** | Linux (Debian-based) |
| **Storage** | 512GB NVMe SSD |
| **Root partition** | 102GB |
| **Home partition** | 374GB (Docker data lives here) |
| **Docker data** | `/home/docker-projects/` |
| **Symlink** | `/mnt/ssd/docker-projects/` → `/home/docker-projects/` |

## Running Services (15 containers)

| Service | Port | External URL | Status |
|---------|------|--------------|--------|
| **Caddy** | 8080 | - | Reverse proxy |
| **Cloudflare Tunnel** | 2000 | - | 2 replicas + metrics |
| **Jellyfin** | 8096 | jellyfin.gmojsoski.com | Media server |
| **KitchenOwl** | 8092 | shopping.gmojsoski.com | 27 recipes |
| **Vaultwarden** | 8082 | vault.gmojsoski.com | Password manager |
| **Nextcloud** | 8081 | cloud.gmojsoski.com | PostgreSQL backend |
| **Uptime Kuma** | 3001 | - | Monitoring |
| **GoatCounter** | 8088 | analytics.gmojsoski.com | Analytics |
| **Homepage** | 8000 | - | Dashboard |
| **Portainer** | 9000 | - | Docker UI |
| **Gokapi** | 8091 | files.gmojsoski.com | File sharing |
| **TravelSync** | 8000 | tickets.gmojsoski.com | Travel docs |
| **Watchtower** | - | - | Auto-updates 2 AM |
| **Nginx (Vaultwarden)** | 8083 | - | iOS DELETE fix |

## Systemd Services

| Service | Port | URL |
|---------|------|-----|
| **Planning Poker** | 3000 | poker.gmojsoski.com |
| **Bookmarks** | 5000 | bookmarks.gmojsoski.com |
| **Gokapi** | 8091 | files.gmojsoski.com |

## Key Paths

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

### Config Files
```
/home/docker-projects/caddy/config/Caddyfile
/usr/local/bin/enhanced-health-check.sh
/var/log/enhanced-health-check.log
```

## Common Commands

### Check all containers
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Restart a service
```bash
cd /home/docker-projects/<service>
docker compose restart
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

### Emergency fix all services
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```

## Watchtower Configuration

- **Schedule**: Daily at 2:00 AM UTC
- **Excluded** (manual updates only):
  - Nextcloud
  - Vaultwarden
  - Jellyfin
  - KitchenOwl

## Slack Notifications

| Timer | Schedule | Purpose |
|-------|----------|---------|
| `slack-goatcounter-weekly.timer` | Sundays 10 AM | Weekly analytics report |
| `slack-pi-monitoring.timer` | (if enabled) | Pi server monitoring |

## Backup System

### Local Backups

| Service | Location | Schedule |
|---------|----------|----------|
| Vaultwarden | `/mnt/ssd/backups/vaultwarden/` | Daily 2 AM |
| Nextcloud | `/mnt/ssd/backups/nextcloud/` | Daily 2 AM |
| KitchenOwl | `/mnt/ssd/backups/kitchenowl/` | Daily 2 AM |
| Travelsync | `/mnt/ssd/backups/travelsync/` | Daily 2 AM |

**Retention**: 30 backups per service

### Offsite Backup (Backblaze B2)

- **Provider**: Backblaze B2 Cloud Storage
- **Bucket**: `Goce-Lenovo`
- **Location**: `b2-backup:Goce-Lenovo/`
- **Sync Schedule**: Daily at 3:00 AM (after local backups)
- **Sync Script**: `/usr/local/bin/sync-backups-to-b2.sh`
- **Log File**: `/var/log/rclone-sync.log`
- **Status**: ✅ Configured and running (443 files synced)

**Manual Commands**:
```bash
# Sync now
rclone sync /mnt/ssd/backups/ b2-backup:Goce-Lenovo/

# List files in B2
rclone ls b2-backup:Goce-Lenovo/

# Check sync logs
tail -f /var/log/rclone-sync.log
```

**Note**: Script excludes `nextcloud-data-extra-*/data/**` due to permission restrictions.

## KitchenOwl Recipe Import

- **Current recipes**: 27
- **Import script**: `scripts/import-recipes-to-kitchenowl.py`
- **Database**: `/home/docker-projects/kitchenowl/data/database.db`

### Import recipes from Word docs
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts"
python3 import-recipes-to-kitchenowl.py ~/Downloads/*.docx
```

## Git Repository

- **Local**: `/home/goce/Desktop/Cursor projects/Pi-version-control/`
- **Remote**: https://github.com/abracadaniel92/lenovo-version-control

## Troubleshooting

### Services not accessible externally
```bash
# Check and restart Cloudflare tunnel
docker logs cloudflared-cloudflared-1
cd /home/docker-projects/cloudflared && docker compose restart
```

### Container keeps restarting
```bash
docker logs <container-name>
docker inspect <container-name> --format '{{.State.Health}}'
```

### Database locked errors
```bash
docker compose stop  # Stop first
# Make changes
docker compose up -d  # Restart
```

## Recent Changes (January 2026)

1. ✅ Removed Kavita (replaced by Jellyfin for books)
2. ✅ Removed Umami & Plausible analytics (using GoatCounter)
3. ✅ Enabled Watchtower with exclusions for critical services
4. ✅ Moved docker data from root to /home (339GB free)
5. ✅ Fixed KitchenOwl and created recipe import script
6. ✅ Updated Slack notification scripts
7. ✅ Cleaned up duplicate health checks
8. ✅ Fixed Vaultwarden iOS DELETE method issue (via Nginx proxy)
9. ✅ Added 2 Cloudflare Tunnel replicas for redundancy
10. ✅ **Fixed health check script** (Jan 2, 2026) - Now correctly detects Docker containers instead of non-existent systemd service
11. ✅ **Added Pi-hole setup guide** for Raspberry Pi 4 (192.168.1.137)
12. ✅ **Investigated and fixed external access issues** - See `EXTERNAL_ACCESS_INVESTIGATION.md`
13. ✅ **Configured Backblaze B2 offsite backup** (Jan 2, 2026) - rclone sync to B2 daily at 3 AM
14. ✅ **Added Cloudflare Tunnel metrics endpoint** (Jan 2, 2026) - Metrics exposed on port 2000, accessible at http://localhost:2000/metrics
15. ✅ **Created Uptime Kuma + ntfy.sh notification setup guide** - See `docs/UPTIME_KUMA_NTFY_SETUP.md`
