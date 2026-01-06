# Daily Operations Guide

## Health Checks

### Check Service Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
systemctl status planning-poker bookmarks gokapi
```

### View Logs
```bash
# Specific service
docker compose logs -f <service>

# All services
docker ps --format "{{.Names}}" | xargs -I {} docker logs {} --tail 50
```

## Backup Procedures

### Automated Backups
- Daily backups run at 2:00 AM for critical services
- Location: `/mnt/ssd/backups/`

### Manual Backup
```bash
# All critical services
bash scripts/backup-all-critical.sh

# Individual services
bash scripts/backup-vaultwarden.sh
bash scripts/backup-nextcloud.sh
bash scripts/backup-kitchenowl.sh
bash scripts/backup-travelsync.sh
```

### Backup Retention
- Last 30 backups per service
- Managed by `scripts/backup-retention-helper.sh`

## Updates

### Update a Service
```bash
cd /home/docker-projects/<service>
docker compose pull
docker compose up -d
```

### Watchtower Auto-Updates
- Updates containers daily at 2 AM
- **Excluded** (manual updates only): Nextcloud, Vaultwarden, Jellyfin, KitchenOwl

## Monitoring

### Health Check Status
```bash
systemctl status enhanced-health-check.timer
tail -50 /var/log/enhanced-health-check.log
```

### External Monitoring
- Uptime Kuma: http://localhost:3001
- Checks every 60 seconds
- Sends alerts on failures

