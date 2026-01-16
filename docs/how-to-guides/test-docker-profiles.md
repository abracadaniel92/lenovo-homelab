# Testing Docker Profiles & Service Dependencies

This guide explains how to test and verify that Step 5 (Docker Profiles & Service Dependency Ordering) is working correctly.

## Quick Test Script

Run the automated test script:

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/test-step5-profiles.sh"
```

This script will:
- ✅ Validate all docker-compose.yml files
- ✅ Check health checks are configured
- ✅ Verify dependency conditions are set
- ✅ Test profiles are configured correctly
- ✅ Verify critical services have no profiles

## Manual Testing Steps

### 1. Test Health Checks

Check that services wait for their dependencies to be healthy:

```bash
# Start Nextcloud database only
cd /home/apps/nextcloud
docker compose up -d db

# Check database health status
docker inspect nextcloud-postgres | grep -A 10 Health

# Wait for database to be healthy (should show "healthy")
watch -n 2 'docker inspect nextcloud-postgres --format "{{.State.Health.Status}}"'

# Start Nextcloud app (should wait for DB to be healthy)
docker compose up -d app

# Check app logs (should show connection successful)
docker logs nextcloud-app | tail -20
```

### 2. Test Profile-Based Startup

#### Test Critical Services (No Profiles - Always Start)

```bash
# Critical services should start without profiles
cd /home/docker-projects/caddy
docker compose down
docker compose up -d
docker compose ps  # Should show caddy running

cd /home/docker-projects/vaultwarden
docker compose down
docker compose up -d
docker compose ps  # Should show vaultwarden running
```

#### Test Profiled Services (Require Profiles)

```bash
# Start Jellyfin with media profile
cd /home/docker-projects/jellyfin
docker compose down
docker compose --profile media up -d
docker compose ps  # Should show jellyfin running

# Try starting without profile (should not start)
docker compose down
docker compose up -d  # Should show "No services to start" or similar

# Start with all profile
docker compose --profile all up -d
docker compose ps  # Should show jellyfin running
```

#### Test Productivity Profile

```bash
# Start Mattermost with productivity profile
cd /home/docker-projects/mattermost
docker compose --profile productivity up -d

# Check that database starts first (from dependencies)
docker compose ps | grep mattermost

# Verify database is healthy before app starts
docker inspect mattermost-postgres --format "{{.State.Health.Status}}"
```

### 3. Test Dependency Ordering

Test that services wait for dependencies to be healthy:

```bash
# Stop all services
cd /home/apps/nextcloud
docker compose down

# Start everything at once
docker compose up -d

# Watch startup order (database should start first, app waits for health)
docker compose logs -f

# In another terminal, check startup timestamps
docker inspect nextcloud-postgres --format "{{.State.StartedAt}}"
docker inspect nextcloud-app --format "{{.State.StartedAt}}"
# App should start AFTER database is healthy
```

### 4. Test Selective Startup During Maintenance

Simulate maintenance scenario - start only critical services:

```bash
# Stop all profiled services
for dir in /home/docker-projects/{jellyfin,mattermost,paperless,outline,uptime-kuma,goatcounter,portainer}/; do
  cd "$dir" && docker compose down 2>/dev/null
done

# Start only critical services
for dir in /home/docker-projects/{caddy,cloudflared,vaultwarden,nextcloud}/; do
  cd "$dir" && docker compose up -d 2>/dev/null
done

# Verify only critical services are running
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "caddy|cloudflared|vaultwarden|nextcloud"

# Start productivity tools when needed
cd /home/docker-projects/mattermost && docker compose --profile productivity up -d
cd /home/docker-projects/paperless && docker compose --profile productivity up -d

# Verify productivity services are running
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "mattermost|paperless"
```

### 5. Test Profile Validation

Verify profile configuration:

```bash
# Check Jellyfin profiles
cd /home/docker-projects/jellyfin
docker compose config | grep -A 3 profiles
# Should show: media, all

# Check Mattermost profiles
cd /home/docker-projects/mattermost
docker compose config | grep -A 3 profiles
# Should show: productivity, all (for mattermost service)
# Should show: productivity, databases, all (for database service)

# Check critical services have no profiles
cd /home/docker-projects/caddy
docker compose config | grep profiles
# Should show nothing (no profiles)
```

## Expected Results

### ✅ Health Checks Working

- Nextcloud database should show "healthy" status
- Nextcloud app should start only after DB is healthy
- Mattermost should wait for database health check
- Outline should wait for PostgreSQL and Redis health checks

### ✅ Profiles Working

- Critical services (Caddy, Vaultwarden, Nextcloud) start without profiles
- Profiled services (Jellyfin, Mattermost, etc.) only start with `--profile` flag
- Services can belong to multiple profiles
- `--profile all` starts all profiled services

### ✅ Dependencies Working

- Databases start before applications
- Applications wait for database health checks
- Startup order is: DB → Wait for healthy → App starts

## Troubleshooting

### Services Not Starting with Profiles

If profiled services don't start:

```bash
# Verify profile is in docker-compose.yml
cd /home/docker-projects/jellyfin
docker compose config | grep -A 3 profiles

# Check for syntax errors
docker compose config > /dev/null && echo "Config valid" || echo "Config invalid"
```

### Dependencies Not Waiting

If apps start before dependencies are ready:

```bash
# Check dependency condition
cd /home/apps/nextcloud
docker compose config | grep -A 5 depends_on

# Should show: condition: service_healthy
```

### Health Checks Not Working

If health checks fail:

```bash
# Check health check configuration
docker compose config | grep -A 10 healthcheck

# Test health check manually
docker exec nextcloud-postgres pg_isready -U nextcloud -d nextcloud
```

## Verification Checklist

- [ ] All docker-compose.yml files are valid (no syntax errors)
- [ ] Health checks are configured on databases
- [ ] Apps wait for database health checks
- [ ] Critical services start without profiles
- [ ] Profiled services only start with `--profile` flag
- [ ] `--profile all` starts all profiled services
- [ ] Dependency ordering works (DB → App)
- [ ] Selective startup works (can start only critical services)

## Success Criteria

✅ All automated tests pass  
✅ Manual tests show correct behavior  
✅ Services start in correct order  
✅ Profiles work as expected  
✅ Health checks ensure dependencies are ready

