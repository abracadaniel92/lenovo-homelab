# Mattermost - Team Communication Platform

Mattermost is an open-source, self-hosted Slack alternative for team communication. This setup is configured for **local use only** (no external access via Caddy/Cloudflare).

## Overview

- **Port**: 8065
- **Access**: 
  - **External**: `https://mattermost.gmojsoski.com` (via Caddy/Cloudflare)
  - **Internal**: `http://localhost:8065`
- **Database**: PostgreSQL 15
- **Image**: `mattermost/mattermost-team-edition:latest`
- **Status**: ⚠️ May experience occasional instability - monitor logs if issues occur

## Quick Start

1. **Navigate to the Mattermost directory:**
   ```bash
   cd "/home/goce/Desktop/Cursor projects/Pi-version-control/docker/mattermost"
   ```

2. **Start Mattermost:**
   ```bash
   docker compose up -d
   ```

3. **Check logs:**
   ```bash
   docker compose logs -f mattermost
   ```

4. **Access Mattermost:**
   - Open your browser and go to: `http://localhost:8065`
   - Create your first admin account

## First-Time Setup

**Admin Account Already Created:**
- Username: `admin`
- Email: `admin@gmojsoski.com`
- Password: `TempPass123!` (**CHANGE THIS IMMEDIATELY!**)
- Initial Team: "Main Team" (already created)

**To Access:**
1. Go to `https://mattermost.gmojsoski.com` (or `http://localhost:8065` locally)
2. Log in with the admin credentials above
3. Select "Main Team" when prompted
4. **IMPORTANT**: Change the admin password immediately:
   - Click your profile icon → **Settings** → **Security** → **Change Password**
5. You can then:
   - Create additional teams and channels
   - Invite other users
   - Configure settings via System Console

## Configuration

### Environment Variables

Key configuration options in `docker-compose.yml`:

- `MM_SERVICESETTINGS_SITEURL`: Set to `http://localhost:8065` for local use
- `MM_SERVICESETTINGS_ENABLELOCALMODE`: Enabled for local operation
- `MM_EMAILSETTINGS_ENABLESIGNUPWITHEMAIL`: Disabled (local only)

### Data Persistence

All data is stored in Docker volumes:
- `mattermost-data`: User uploads and files
- `mattermost-config`: Configuration files
- `mattermost-logs`: Application logs
- `mattermost-plugins`: Installed plugins
- `mattermost-postgres-data`: Database data

## Management Commands

### Stop Mattermost
```bash
docker compose down
```

### Stop and Remove Data (⚠️ Destroys all data)
```bash
docker compose down -v
```

### View Logs
```bash
# All services
docker compose logs -f

# Mattermost only
docker compose logs -f mattermost

# PostgreSQL only
docker compose logs -f mattermost-postgres
```

### Restart Mattermost
```bash
docker compose restart mattermost
```

### Backup Database
```bash
docker exec mattermost-postgres pg_dump -U mmuser mattermost > mattermost-backup-$(date +%Y%m%d).sql
```

### Restore Database
```bash
docker exec -i mattermost-postgres psql -U mmuser mattermost < mattermost-backup-YYYYMMDD.sql
```

## Troubleshooting

### Container won't start
- Check logs: `docker compose logs mattermost`
- Verify PostgreSQL is healthy: `docker compose ps`
- Check port 8065 is not in use: `ss -tulpn | grep 8065`

### Database connection errors
- Wait for PostgreSQL to be ready (healthcheck should pass)
- Check PostgreSQL logs: `docker compose logs mattermost-postgres`
- Verify credentials match in both services

### Can't access web interface
- Verify container is running: `docker compose ps`
- Check port binding: `docker compose port mattermost 8065`
- Test locally: `curl http://localhost:8065`

## Security Notes

- **Local Only**: This setup is configured for local network access only
- **Default Credentials**: Change the PostgreSQL password in production
- **No SSL**: For local use only - add SSL if exposing externally
- **First User**: The first user account created becomes the admin

## Adding External Access Later

If you want to expose Mattermost externally later:

1. **Update Caddyfile** (`docker/caddy/Caddyfile`):
   ```caddyfile
   @mattermost host mattermost.gmojsoski.com
   handle @mattermost {
       reverse_proxy http://172.17.0.1:8065
   }
   ```

2. **Update Cloudflare config** (`~/.cloudflared/config.yml`):
   ```yaml
   - hostname: mattermost.gmojsoski.com
     service: http://localhost:8080
   ```

3. **Update Mattermost SiteURL** in `docker-compose.yml`:
   ```yaml
   MM_SERVICESETTINGS_SITEURL: https://mattermost.gmojsoski.com
   ```

4. **Restart services** in order:
   - Caddy first: `docker compose -f docker/caddy/docker-compose.yml restart`
   - Cloudflared second: `docker compose -f docker/cloudflared/docker-compose.yml restart`
   - Mattermost: `docker compose restart mattermost`

## Resources

- [Mattermost Documentation](https://docs.mattermost.com/)
- [Mattermost Configuration Options](https://docs.mattermost.com/configure/configuration-settings.html)
- [Mattermost Docker Installation](https://docs.mattermost.com/install/docker-local-machine.html)

