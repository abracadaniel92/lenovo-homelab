# Mattermost - Team Communication Platform

Mattermost is an open-source, self-hosted Slack alternative for team communication. This setup is configured for both **local and external access**.

## Overview

- **Port**: 8065 (direct), 8080 (via Caddy)
- **Access**: 
  - **External HTTPS**: `https://mattermost.gmojsoski.com` (via Cloudflare Tunnel)
  - **Local Network HTTP**: `http://mattermost.gmojsoski.com:8080` (via Caddy - **NOTE: Port 8080 required for local domain access**)
  - **Direct Local**: `http://localhost:8065` or `http://192.168.1.97:8065`
- **Database**: PostgreSQL 15
- **Image**: `mattermost/mattermost-team-edition:latest`
- **Status**: ⚠️ May experience occasional instability - monitor logs if issues occur

**Important for Local Access:**
- When accessing via domain name on local network, you **must** specify port 8080: `http://mattermost.gmojsoski.com:8080`
- Port 80 is not available - Caddy listens on port 8080 on the host
- For HTTPS, use `https://mattermost.gmojsoski.com` (goes through Cloudflare)

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
   - **External**: `https://mattermost.gmojsoski.com` (recommended)
   - **Local Network**: `http://mattermost.gmojsoski.com:8080` (note: port 8080 required)
   - **Direct Local**: `http://localhost:8065`

## First-Time Setup

**Admin Account Already Created:**
- Username: `admin`
- Email: `admin@gmojsoski.com`
- Password: `TempPass123!` (**CHANGE THIS IMMEDIATELY!**)
- Initial Team: "Main Team" (already created)

**To Access:**
1. Go to one of these URLs:
   - **External (HTTPS)**: `https://mattermost.gmojsoski.com` (recommended)
   - **Local Network (HTTP)**: `http://mattermost.gmojsoski.com:8080` (note: port 8080 is required)
   - **Direct Local**: `http://localhost:8065`
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

- `MM_SERVICESETTINGS_SITEURL`: Set to `https://mattermost.gmojsoski.com` for external access
- `MM_SERVICESETTINGS_ENABLELOCALMODE`: Disabled (external access enabled)
- `MM_EMAILSETTINGS_ENABLESIGNUPWITHEMAIL`: Enabled (external access)
- `MM_EMAILSETTINGS_ENABLESIGNINWITHEMAIL`: Enabled
- `MM_SERVICESETTINGS_ENABLEOPENSERVER`: Enabled (allows user sign-up)

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

### Can't access web interface locally
- **Port 80 not working**: Caddy listens on port 8080, not 80. Use:
  - `http://mattermost.gmojsoski.com:8080` (local network with domain)
  - `http://localhost:8065` (direct access)
  - `https://mattermost.gmojsoski.com` (external HTTPS via Cloudflare)
- Verify container is running: `docker compose ps`
- Check port binding: `docker compose port mattermost 8065`
- Test locally: `curl http://localhost:8065`
- Test via Caddy: `curl -H "Host: mattermost.gmojsoski.com" http://localhost:8080`

### Local domain access issues
- **Pi-hole DNS**: Ensure `mattermost.gmojsoski.com` points to server IP (192.168.1.97) in Pi-hole Local DNS Records
- **Port required**: When accessing via domain locally, you **must** use port 8080: `http://mattermost.gmojsoski.com:8080`
- **Why port 8080?**: Caddy is mapped to host port 8080 (container port 80 → host port 8080)
- **HTTPS access**: Use `https://mattermost.gmojsoski.com` which goes through Cloudflare Tunnel (works both locally and externally)

## Security Notes

- **Local Only**: This setup is configured for local network access only
- **Default Credentials**: Change the PostgreSQL password in production
- **No SSL**: For local use only - add SSL if exposing externally
- **First User**: The first user account created becomes the admin

## Local Network Access Notes

**Important**: Mattermost is already exposed externally. For local network access:

1. **Via Domain Name (Pi-hole DNS)**:
   - Use `http://mattermost.gmojsoski.com:8080` (port 8080 is required)
   - Pi-hole should resolve `mattermost.gmojsoski.com` to your server IP (192.168.1.97)
   - Port 80 is not available - Caddy listens on port 8080

2. **Via HTTPS**:
   - Use `https://mattermost.gmojsoski.com` (goes through Cloudflare Tunnel)
   - Works both locally and externally

3. **Direct Access**:
   - Use `http://localhost:8065` (from server itself)
   - Use `http://192.168.1.97:8065` (from other devices on network)

**Why Port 8080?**
- Caddy container listens on port 80 internally
- Docker maps container port 80 → host port 8080
- Port 80 is not bound on the host (to avoid conflicts)
- This is standard for all services in this setup

## Adding External Access Later (Already Done)

Mattermost is already exposed externally. If you need to reconfigure:

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

## Local Network Access Explained

### How Other Services Work Locally

All services follow the same pattern:
- **Caddy listens on port 8080** (not port 80) on the host
- **Pi-hole DNS resolves** domain names to the server IP (192.168.1.97) for local access
- **HTTP access requires port 8080**: `http://service.gmojsoski.com:8080` (when Pi-hole resolves to local IP)
- **HTTPS via Cloudflare**: `https://service.gmojsoski.com` (only works if DNS resolves to Cloudflare IP, not local IP)

**Note**: The documentation saying `http://jellyfin.gmojsoski.com` (without port) is outdated. All services require port 8080 for HTTP local access when using Pi-hole DNS that resolves to local IP. For HTTPS to work through Cloudflare, DNS must resolve to Cloudflare's IP (not the local IP).

### Why Port 8080 for Local Domain Access?

When accessing Mattermost via domain name on your local network:
- **Port 80 is not available**: Caddy listens on port 8080 on the host (mapped from container port 80)
- **Port 80 is not bound** on the host to avoid conflicts with other services
- **Pi-hole DNS resolves correctly**: `mattermost.gmojsoski.com` → `192.168.1.97`
- **Solution**: Use `http://mattermost.gmojsoski.com:8080` for local HTTP access
- **Alternative**: Use `https://mattermost.gmojsoski.com` which goes through Cloudflare Tunnel (works both locally and externally)

### Pi-hole Configuration (On Different Device)

Since Pi-hole is on a different device (Raspberry Pi), you need to:

1. **Access Pi-hole Admin**:
   - Go to `http://[PI-HOLE-IP]/admin` on your Pi-hole device
   - Navigate to: **Local DNS → DNS Records**

2. **Add Mattermost DNS Record**:
   - Domain: `mattermost.gmojsoski.com`
   - IP: `192.168.1.97` (your server IP)
   - Click **Add**

3. **Verify DNS Resolution** (from any device on network):
   ```bash
   nslookup mattermost.gmojsoski.com
   # Should show: 192.168.1.97
   ```

4. **Access Mattermost**:
   - **HTTP (local, fast)**: `http://mattermost.gmojsoski.com:8080` ✅ (requires port 8080)
   - **HTTPS (via Cloudflare)**: `https://mattermost.gmojsoski.com` (only works if DNS resolves to Cloudflare IP, not local IP)
   - **Direct IP (bypasses Caddy)**: `http://192.168.1.97:8065` ✅

**Important Notes**:
- **For local HTTP access**: Pi-hole DNS should resolve to local IP (192.168.1.97), use port 8080
- **For HTTPS via Cloudflare**: DNS should resolve to Cloudflare IP (not local IP). If Pi-hole resolves to local IP, HTTPS will fail because there's no listener on port 443
- **Recommendation**: Use `http://mattermost.gmojsoski.com:8080` for fast local access, or `https://mattermost.gmojsoski.com` if you want to go through Cloudflare (requires DNS to resolve to Cloudflare IP)

### Is Nginx Needed?

**No, nginx is NOT required.** Mattermost works perfectly with Caddy as a reverse proxy. Some older guides mention nginx, but:
- Caddy handles reverse proxying directly
- Caddy provides automatic HTTPS (via Cloudflare)
- Adding nginx would be redundant and add unnecessary complexity

The setup uses:
1. **Mattermost** → listens on port 8065
2. **Caddy** → reverse proxies to Mattermost on port 8065
3. **Cloudflare Tunnel** → provides external HTTPS access

No nginx needed!

## Resources

- [Mattermost Documentation](https://docs.mattermost.com/)
- [Mattermost Configuration Options](https://docs.mattermost.com/configure/configuration-settings.html)
- [Mattermost Docker Installation](https://docs.mattermost.com/install/docker-local-machine.html)

