# KitchenOwl Data Loss Prevention

## Problem
KitchenOwl data (households, users, shopping lists) was lost when the container was recreated. This guide ensures this never happens again.

## Prevention Measures Implemented

### 1. ✅ Bind Mount with Explicit Permissions
The `docker-compose.yml` now uses:
```yaml
volumes:
  - ./data:/app/data:rw  # Explicit read-write, ensures data persists
```

**Why this helps:**
- Data is stored on the host filesystem (`/mnt/ssd/docker-projects/kitchenowl/data/`)
- Data persists even if container is recreated
- No dependency on Docker volumes

### 2. ✅ Automated Daily Backups
A cron job runs daily at 2 AM to backup the database:
```bash
0 2 * * * goce bash /home/goce/Desktop/Cursor\ projects/Pi-version-control/scripts/backup-kitchenowl.sh
```

**Backup location:** `/mnt/ssd/backups/kitchenowl/`
- Keeps last 30 backups automatically
- Timestamped: `kitchenowl-YYYYMMDD-HHMMSS.db`

### 3. ✅ Manual Backup Script
Create backups anytime:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-kitchenowl.sh"
```

### 4. ✅ Restore Script
Restore from backup if needed:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/restore-kitchenowl.sh"
```

### 5. ✅ Health Check
Container has health check to ensure it's working properly.

## Before Making Changes

**ALWAYS backup before:**
- Updating docker-compose.yml
- Changing network configuration
- Updating the container image
- Making any changes that require container recreation

**Quick backup command:**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-kitchenowl.sh"
```

## Current Data Location

- **Database:** `/mnt/ssd/docker-projects/kitchenowl/data/kitchenowl.db`
- **Backups:** `/mnt/ssd/backups/kitchenowl/`
- **Container path:** `/app/data/kitchenowl.db`

## Verification

Check that data is in bind mount (not Docker volume):
```bash
# Should show the database file
ls -lah /mnt/ssd/docker-projects/kitchenowl/data/kitchenowl.db

# Should show bind mount (not volume)
docker inspect kitchenowl --format='{{range .Mounts}}{{.Type}} {{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

## Recovery Procedure

If data is lost:

1. **Check for backups:**
   ```bash
   ls -lh /mnt/ssd/backups/kitchenowl/
   ```

2. **Restore from backup:**
   ```bash
   bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/restore-kitchenowl.sh"
   ```

3. **If no backup, check Docker volumes:**
   ```bash
   docker volume ls
   docker volume inspect <volume-name>
   ```

## Best Practices

1. **Always use bind mounts** (not Docker volumes) for persistent data
2. **Backup before changes** - Run backup script before any container modifications
3. **Verify data location** - Ensure database is in bind mount, not volume
4. **Test backups** - Periodically verify backups are working
5. **Document changes** - Note any changes that affect data storage

## Monitoring

Check backup logs:
```bash
tail -f /var/log/kitchenowl-backup.log
```

Verify backups are being created:
```bash
ls -lh /mnt/ssd/backups/kitchenowl/ | tail -5
```

## Summary

✅ **Data persistence:** Bind mount ensures data survives container recreation  
✅ **Automated backups:** Daily backups at 2 AM  
✅ **Manual backups:** Script available for on-demand backups  
✅ **Restore capability:** Easy restore from any backup  
✅ **Health monitoring:** Container health check ensures it's working  

**Your KitchenOwl data is now protected!** 🛡️

