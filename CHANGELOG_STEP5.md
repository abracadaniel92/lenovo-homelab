# Step 5 Complete: Docker Profiles & Service Dependency Ordering ✅

**Date:** 2026-01-16
**Status:** ✅ Complete

## Summary

Implemented Docker Compose profiles for service grouping and improved service dependency ordering with health checks. This allows selective startup of services and ensures proper startup order.

## Features

### 1. Service Dependency Improvements ✅

**Nextcloud:**
- Added health check to PostgreSQL database
- Updated app to wait for database health check (`service_healthy`)
- Ensures database is ready before app starts

**Mattermost:**
- Already had health check on database ✅
- Already waits for database health check ✅

**Outline:**
- Added health check conditions to dependencies
- Updated app to wait for PostgreSQL and Redis health checks (`service_healthy`)

**Paperless:**
- Updated to wait for Redis to start (`service_started`)

### 2. Docker Compose Profiles ✅

Services are organized into profiles for selective startup:

| Profile | Services | Purpose |
|---------|----------|---------|
| **Critical** (no profile) | Caddy, Cloudflared, Vaultwarden, Nextcloud | Always start - essential infrastructure |
| **`media`** | Jellyfin | Media services |
| **`productivity`** | Paperless, Mattermost, Outline | Productivity and collaboration tools |
| **`utilities`** | Uptime Kuma, GoatCounter, Portainer | Utility services |
| **`monitoring`** | Uptime Kuma | Monitoring services |
| **`databases`** | Nextcloud DB, Mattermost DB, Paperless Redis, Outline DB/Redis | Database services (auto-started with dependent services) |
| **`all`** | All profiled services | Convenience profile to start all services |

### 3. Health Checks Added ✅

**Nextcloud Database:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U nextcloud -d nextcloud"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

**Outline Dependencies:**
- Already had health checks ✅
- Updated to use `condition: service_healthy` ✅

## Files Modified

### Docker Compose Files
- `docker/nextcloud/docker-compose.yml` - Added health check to DB, updated app dependency
- `docker/paperless/docker-compose.yml` - Added profiles, updated dependency condition
- `docker/mattermost/docker-compose.yml` - Added profiles to database and app
- `docker/outline/docker-compose.yml` - Added profiles, updated dependency conditions
- `docker/jellyfin/docker-compose.yml` - Added media profile
- `docker/uptime-kuma/docker-compose.yml` - Added utilities and monitoring profiles
- `docker/goatcounter/docker-compose.yml` - Added utilities profile
- `docker/portainer/docker-compose.yml` - Added utilities profile

### Documentation
- `README.md` - Added "Docker Profiles & Service Dependencies" section with usage examples

## Service Startup Behavior

### Critical Services (Always Start)
- **Caddy** - Reverse proxy (no profile, always starts)
- **Cloudflared** - Tunnel (no profile, always starts)
- **Vaultwarden** - Password manager (no profile, always starts)
- **Nextcloud** - File storage (no profile, always starts)

### Profiled Services (Selective Startup)
- **Jellyfin** - `--profile media` or `--profile all`
- **Mattermost** - `--profile productivity` or `--profile all`
- **Paperless** - `--profile productivity` or `--profile all`
- **Outline** - `--profile productivity` or `--profile all`
- **Uptime Kuma** - `--profile utilities` or `--profile monitoring` or `--profile all`
- **GoatCounter** - `--profile utilities` or `--profile all`
- **Portainer** - `--profile utilities` or `--profile all`

## Usage Examples

### Start All Services
```bash
# Start critical services (always running)
cd /home/docker-projects/caddy && docker compose up -d
cd /home/docker-projects/cloudflared && docker compose up -d
cd /home/docker-projects/vaultwarden && docker compose up -d
cd /home/apps/nextcloud && docker compose up -d

# Start all profiled services
for dir in /home/docker-projects/*/; do
  cd "$dir" && docker compose --profile all up -d 2>/dev/null
done
```

### Start Selective Services
```bash
# Start only media services
cd /home/docker-projects/jellyfin && docker compose --profile media up -d

# Start only productivity tools
cd /home/docker-projects/mattermost && docker compose --profile productivity up -d
cd /home/docker-projects/paperless && docker compose --profile productivity up -d
cd /home/docker-projects/outline && docker compose --profile productivity up -d
```

### Start Utilities Only
```bash
cd /home/docker-projects/uptime-kuma && docker compose --profile utilities up -d
cd /home/docker-projects/goatcounter && docker compose --profile utilities up -d
cd /home/docker-projects/portainer && docker compose --profile utilities up -d
```

## Benefits

1. **Selective Startup** - Start only services you need (e.g., during maintenance)
2. **Resource Management** - Reduce resource usage by stopping non-essential services
3. **Dependency Ordering** - Services wait for dependencies to be healthy before starting
4. **Maintenance** - Easier to test and maintain individual service groups
5. **Startup Reliability** - Health checks ensure dependencies are ready before apps start

## Dependency Order

1. **Infrastructure** - Caddy, Cloudflared (no dependencies)
2. **Databases** - Nextcloud DB, Mattermost DB, Paperless Redis, Outline DB/Redis
3. **Critical Apps** - Vaultwarden, Nextcloud (waits for DB health)
4. **Productivity Apps** - Paperless, Mattermost, Outline (waits for DB/Redis health)
5. **Media** - Jellyfin (no dependencies)
6. **Utilities** - Uptime Kuma, GoatCounter, Portainer (no dependencies)

## Verification

All docker-compose.yml files validated successfully:
- ✅ Nextcloud config valid
- ✅ Jellyfin config valid
- ✅ Mattermost config valid
- ✅ Paperless config valid
- ✅ Outline config valid
- ✅ Uptime Kuma config valid
- ✅ GoatCounter config valid
- ✅ Portainer config valid

## Next Steps

This completes Step 5 of the infrastructure improvements. All planned steps are now complete:
- ✅ Step 1: Split Caddyfile and Cloudflare validation
- ✅ Step 2: Fix port conflict (TravelSync/Homepage)
- ✅ Step 3: Add resource limits to Docker containers
- ✅ Step 4: Create backup verification system
- ✅ Step 5: Docker profiles and service dependency ordering

