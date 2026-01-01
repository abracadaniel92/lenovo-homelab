# Watchtower Auto-Update Configuration

## Overview
Watchtower automatically updates Docker containers when new images are available.

**Location:** `/mnt/ssd/docker-projects/watchtower/`

## Schedule
- **Runs:** Daily at 2:00 AM UTC
- **Cleanup:** Removes old images after update

## Excluded Services (Manual Updates Only)
These services have `com.centurylinklabs.watchtower.enable=false` label:

| Service | Reason |
|---------|--------|
| **Nextcloud** | Complex migrations, plugins may break |
| **Vaultwarden** | Critical passwords, needs careful upgrades |
| **Jellyfin** | Media metadata, plugins may break |

## Auto-Updated Services
- KitchenOwl
- Caddy
- Uptime Kuma
- GoatCounter
- Homepage
- Portainer
- Cloudflare Tunnel

## Configuration
```yaml
services:
  watchtower:
    image: containrrr/watchtower:latest
    environment:
      - DOCKER_API_VERSION=1.44  # Required for newer Docker
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *  # Daily at 2 AM
      - WATCHTOWER_INCLUDE_STOPPED=false
      - WATCHTOWER_REVIVE_STOPPED=false
```

## Exclude a Service from Auto-Updates
Add this label to any docker-compose.yml:
```yaml
services:
  your-service:
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
```
Then recreate: `docker compose up -d`

## Manual Commands
```bash
# Check status
docker logs watchtower --tail 20

# Force update check now
docker exec watchtower /watchtower --run-once

# Stop auto-updates
cd /mnt/ssd/docker-projects/watchtower && docker compose down
```

## Troubleshooting
If Watchtower fails with "API version too old":
- Ensure `DOCKER_API_VERSION=1.44` is set in environment

