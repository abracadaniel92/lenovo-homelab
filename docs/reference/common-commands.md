# Common Commands Reference

Quick reference for frequently used commands.

## Docker Services

### Check all containers
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Restart a service
```bash
cd /home/docker-projects/<service>
docker compose restart
```

### View logs
```bash
docker logs <container-name> --tail 50
docker compose logs -f
```

### Check service health
```bash
docker inspect <container-name> --format '{{.State.Health}}'
```

## Cloudflare Tunnel

### Check tunnel status
```bash
docker ps --filter "name=cloudflared"
```

### Restart tunnel
```bash
cd /home/docker-projects/cloudflared
docker compose restart
```

### View metrics
```bash
curl http://localhost:2000/metrics
```

### Check tunnel logs
```bash
docker logs cloudflared-cloudflared-1 --tail 50
```

## Backups

### Run all backups
```bash
bash scripts/backup-all-critical.sh
```

### Run individual backup
```bash
bash scripts/backup-vaultwarden.sh
bash scripts/backup-nextcloud.sh
bash scripts/backup-kitchenowl.sh
bash scripts/backup-travelsync.sh
```

### Sync to Backblaze B2
```bash
sudo /usr/local/bin/sync-backups-to-b2.sh
```

### Check B2 sync status
```bash
rclone ls b2-backup:Goce-Lenovo/
tail -f /var/log/rclone-sync.log
```

## Monitoring

### Check health check logs
```bash
tail -50 /var/log/enhanced-health-check.log
```

### Access Uptime Kuma
```bash
# Local
http://localhost:3001

# Or via external URL if configured
```

### Check external access
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://jellyfin.gmojsoski.com
```

## System Services

### Check systemd services
```bash
systemctl status planning-poker bookmarks gokapi
```

### View service logs
```bash
journalctl -u <service-name> -f
```

## Emergency

### Fix all services
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```

### Fix subdomains (502/404 errors)
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
```

## Git

### Check status
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
git status
```

### Commit and push
```bash
git add -A
git commit -m "Description"
git push origin main
```

---

*Last updated: January 2026*






