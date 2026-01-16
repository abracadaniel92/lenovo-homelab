# Step 5 Testing & Verification Guide

Quick guide to test and confirm Docker Profiles & Service Dependency Ordering is working.

## 🚀 Quick Test Commands

### 1. Validate Configurations

```bash
# Test all modified docker-compose files
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"

# Validate Nextcloud (health checks and dependencies)
cd docker/nextcloud && docker compose config > /dev/null && echo "✅ Nextcloud config valid" || echo "❌ Invalid"

# Validate Mattermost (profiles and health checks)
cd ../mattermost && docker compose config > /dev/null && echo "✅ Mattermost config valid" || echo "❌ Invalid"

# Validate Paperless (profiles and dependencies)
cd ../paperless && docker compose config > /dev/null && echo "✅ Paperless config valid" || echo "❌ Invalid"

# Validate Outline (profiles and health checks)
cd ../outline && docker compose config > /dev/null && echo "✅ Outline config valid" || echo "❌ Invalid"

# Validate Jellyfin (profiles)
cd ../jellyfin && docker compose config > /dev/null && echo "✅ Jellyfin config valid" || echo "❌ Invalid"
```

### 2. Check Health Checks Are Configured

```bash
# Nextcloud DB health check
cd docker/nextcloud && docker compose config | grep -A 5 "db:" | grep healthcheck && echo "✅ Health check found"

# Mattermost DB health check
cd ../mattermost && docker compose config | grep -A 5 "database:" | grep healthcheck && echo "✅ Health check found"

# Outline DB health check
cd ../outline && docker compose config | grep -A 5 "outline-postgres:" | grep healthcheck && echo "✅ Health check found"
```

### 3. Check Dependency Conditions

```bash
# Nextcloud app waits for DB
cd docker/nextcloud && docker compose config | grep -A 3 "app:" | grep "service_healthy" && echo "✅ Dependency condition found"

# Mattermost waits for DB
cd ../mattermost && docker compose config | grep -A 3 "mattermost:" | grep "service_healthy" && echo "✅ Dependency condition found"

# Outline waits for dependencies
cd ../outline && docker compose config | grep -A 5 "outline:" | grep "service_healthy" && echo "✅ Dependency condition found"
```

### 4. Check Profiles Are Configured

```bash
# Jellyfin has media profile
cd docker/jellyfin && docker compose config | grep -A 2 "profiles:" | grep "media" && echo "✅ Media profile found"

# Mattermost has productivity profile
cd ../mattermost && docker compose config | grep -A 2 "profiles:" | grep "productivity" && echo "✅ Productivity profile found"

# Paperless has productivity profile
cd ../paperless && docker compose config | grep -A 2 "profiles:" | grep "productivity" && echo "✅ Productivity profile found"

# Uptime Kuma has utilities profile
cd ../uptime-kuma && docker compose config | grep -A 2 "profiles:" | grep "utilities" && echo "✅ Utilities profile found"
```

### 5. Check Critical Services Have No Profiles

```bash
# Caddy has no profiles (should show nothing)
cd docker/caddy && docker compose config | grep "profiles" && echo "❌ Should not have profiles" || echo "✅ No profiles (correct)"

# Vaultwarden has no profiles
cd ../vaultwarden && docker compose config | grep "profiles" && echo "❌ Should not have profiles" || echo "✅ No profiles (correct)"
```

## 🧪 Automated Test Script

Run the automated test script:

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/test-step5-profiles.sh"
```

This will:
- ✅ Validate all docker-compose.yml files
- ✅ Check health checks are configured
- ✅ Verify dependency conditions are set
- ✅ Test profiles are configured correctly
- ✅ Verify critical services have no profiles

## 📋 Manual Testing (Production)

### Test Profile-Based Startup

```bash
# Start Jellyfin with media profile
cd /home/docker-projects/jellyfin
docker compose down
docker compose --profile media up -d
docker compose ps  # Should show jellyfin running

# Start without profile (should not start services with profiles)
docker compose down
docker compose up -d  # No error, but services with profiles won't start
```

### Test Dependency Ordering

```bash
# Start Nextcloud and watch startup order
cd /home/apps/nextcloud
docker compose down
docker compose up -d

# Watch logs to see database starts first, then app waits
docker compose logs -f

# In another terminal, check health status
watch -n 2 'docker inspect nextcloud-postgres --format "{{.State.Health.Status}}"'
# Should show: starting → healthy (then app starts)
```

### Test Critical Services (No Profiles)

```bash
# Critical services should start without profiles
cd /home/docker-projects/caddy
docker compose down
docker compose up -d  # Should work without --profile
docker compose ps  # Should show caddy running
```

## ✅ Verification Checklist

- [ ] All docker-compose.yml files validate without errors
- [ ] Health checks are configured on databases (Nextcloud, Mattermost, Outline)
- [ ] Apps wait for database health checks (`service_healthy`)
- [ ] Critical services (Caddy, Vaultwarden) have no profiles
- [ ] Profiled services have correct profiles (media, productivity, utilities)
- [ ] Services start in correct order (DB → App)
- [ ] Profile-based startup works (services only start with `--profile`)

## 🎯 Expected Results

### Health Checks
- Nextcloud DB: `healthcheck` configured with `pg_isready`
- Mattermost DB: `healthcheck` configured
- Outline DB/Redis: `healthcheck` configured

### Dependencies
- Nextcloud app: `depends_on: db: condition: service_healthy`
- Mattermost app: `depends_on: database: condition: service_healthy`
- Outline app: `depends_on: outline-postgres: condition: service_healthy`

### Profiles
- **Critical** (no profile): Caddy, Cloudflared, Vaultwarden, Nextcloud
- **`media`**: Jellyfin
- **`productivity`**: Paperless, Mattermost, Outline
- **`utilities`**: Uptime Kuma, GoatCounter, Portainer
- **`monitoring`**: Uptime Kuma
- **`all`**: All profiled services

## 🐛 Troubleshooting

### Services Not Starting with Profiles

```bash
# Check profile is in config
docker compose config | grep -A 3 profiles

# Verify syntax is correct
docker compose config > /dev/null && echo "Valid" || echo "Invalid"
```

### Health Checks Not Working

```bash
# Test health check manually
docker exec nextcloud-postgres pg_isready -U nextcloud -d nextcloud

# Check health status
docker inspect nextcloud-postgres --format "{{.State.Health.Status}}"
```

### Dependencies Not Waiting

```bash
# Check dependency condition
docker compose config | grep -A 5 depends_on

# Should show: condition: service_healthy
```

## 📊 Test Summary

After running tests, you should see:

- ✅ All configs valid
- ✅ Health checks configured
- ✅ Dependencies wait for health checks
- ✅ Profiles configured correctly
- ✅ Critical services have no profiles
- ✅ Profile-based startup works

If all tests pass, Step 5 is working correctly! 🎉

