# Quick Migration Reference

## On Raspberry Pi (Backup)

```bash
cd ~/Desktop/Cursor/Pi-version-control
./backup_pi.sh
```

**What it does:**
- Auto-detects backup SSD
- Backs up everything to `/mnt/backup_ssd/pi_backup_YYYYMMDD_HHMMSS/`
- Creates manifest for verification

**After backup:**
```bash
# Verify backup
ls -la /mnt/backup_ssd/pi_backup_*/
du -sh /mnt/backup_ssd/pi_backup_*

# Unmount safely
sudo umount /mnt/backup_ssd
```

## On ThinkCentre (Restore)

```bash
cd ~/Desktop/Cursor/Pi-version-control
./restore_to_thinkcentre.sh
```

**What it does:**
- Auto-detects backup directory
- Installs Docker & Docker Compose
- Mounts SSD at `/mnt/ssd`
- Restores all configs, data, and credentials
- Downloads x86_64 binaries
- Starts all services

**After restore:**
```bash
# Check services
docker ps
systemctl status gokapi cloudflared

# Update passwords
nano /mnt/ssd/apps/nextcloud/docker-compose.yml
nano /mnt/ssd/docker-projects/pihole/docker-compose.yml
nano /mnt/ssd/docker-projects/documents-to-calendar/.env

# Test services
curl http://localhost:8080  # Caddy
curl http://localhost:8088  # GoatCounter
curl http://localhost:8091  # Gokapi
curl http://localhost:8000/api/health  # Documents-to-Calendar
```

## Important Notes

1. **Architecture**: Pi (ARM64) → ThinkCentre (x86_64) - handled automatically
2. **Passwords**: Update all passwords after restore
3. **Network**: Review network config if needed
4. **Docker Group**: May need to log out/in after restore

## Troubleshooting

```bash
# Docker permission issues
sudo usermod -aG docker $USER
newgrp docker

# Service logs
docker compose logs
journalctl -u gokapi -f
journalctl -u cloudflared -f

# File permissions
sudo chown -R $USER:$USER /mnt/ssd/apps/
sudo chown -R $USER:$USER /mnt/ssd/docker-projects/
```

See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for detailed instructions.

