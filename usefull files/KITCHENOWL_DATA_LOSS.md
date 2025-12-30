# KitchenOwl Data Loss Issue

## Problem
KitchenOwl is asking to create a user, but you already had two users. The database file is missing.

## Root Cause
When we fixed the KitchenOwl network configuration (moved from separate network to bridge network), the container was recreated. The database was likely stored in a Docker volume that wasn't properly migrated to the bind mount.

## Current Status
- ❌ Database file missing: `/mnt/ssd/docker-projects/kitchenowl/data/kitchenowl.db`
- ✅ Data directory exists but is empty
- ✅ Container is running and healthy
- ⚠️  Container was recreated on Dec 30, 2025 at 19:22:33

## Recovery Options

### Option 1: Check Docker Volume (Most Likely)
The old database might be in a Docker volume. Check:

```bash
# List all volumes
docker volume ls

# Inspect the volume that was mounted
docker volume inspect <volume-name>

# Check volume contents (requires sudo)
sudo ls -la /var/lib/docker/volumes/<volume-name>/_data/
```

If you find the database:
```bash
# Copy database from volume to bind mount
sudo cp /var/lib/docker/volumes/<volume-name>/_data/kitchenowl.db /mnt/ssd/docker-projects/kitchenowl/data/
sudo chown goce:goce /mnt/ssd/docker-projects/kitchenowl/data/kitchenowl.db

# Restart KitchenOwl
cd /mnt/ssd/docker-projects/kitchenowl
docker compose restart kitchenowl
```

### Option 2: Check for Backups
Look for any backup files:
```bash
find /mnt/ssd -name "*kitchenowl*.db*" -o -name "*kitchenowl*.backup*" 2>/dev/null
find /mnt/ssd -name "*kitchenowl*.sqlite*" 2>/dev/null
```

### Option 3: Recreate Users (If No Backup)
If the database cannot be recovered, you'll need to recreate your users. Unfortunately, all your shopping lists and data will be lost.

## Prevention for Future

### Always Use Bind Mounts
The current `docker-compose.yml` uses a bind mount:
```yaml
volumes:
  - ./data:/app/data
```

This ensures data persists on the host filesystem.

### Backup Strategy
Create regular backups:
```bash
# Backup script
#!/bin/bash
BACKUP_DIR="/mnt/ssd/backups/kitchenowl"
mkdir -p "$BACKUP_DIR"
cp /mnt/ssd/docker-projects/kitchenowl/data/kitchenowl.db "$BACKUP_DIR/kitchenowl-$(date +%Y%m%d-%H%M%S).db"
```

### Check Data Before Container Changes
Before making changes that require container recreation:
1. Verify data directory has files
2. Create a backup
3. Test the backup can be restored

## Current Configuration
```yaml
services:
  kitchenowl:
    image: tombursch/kitchenowl:latest
    container_name: kitchenowl
    restart: always
    ports:
      - "8092:8080"
    volumes:
      - ./data:/app/data  # ✅ Bind mount - data persists on host
    environment:
      - NODE_ENV=production
      - DATABASE_URL=file:./data/kitchenowl.db
      - JWT_SECRET=change-me-to-a-random-secret
      - BASE_URL=https://shopping.gmojsoski.com
    network_mode: bridge
```

## Next Steps
1. Check Docker volumes for old database
2. If found, copy to bind mount location
3. If not found, check for backups
4. If no backup, recreate users (data will be lost)

## Commands to Check Volume
```bash
# Find the volume
docker volume ls | grep kitchenowl

# If found, inspect it
docker volume inspect <volume-name>

# Check contents (requires sudo)
sudo ls -la /var/lib/docker/volumes/<volume-name>/_data/
```

