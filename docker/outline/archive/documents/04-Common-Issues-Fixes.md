# Common Issues & Fixes

## Service Down (502 Errors)

### Symptoms
- All services accessible internally and directly via Caddy
- External access via Cloudflare Tunnel returning intermittent 502 errors
- Some services returning 502 permanently

### Fixes

#### Cloudflare Tunnel Instability
- **Issue**: Multiple `cloudflared` replicas creating too many connections
- **Fix**: Increased UDP buffer sizes to 25MB
- **Command**: `sudo sysctl -w net.core.wmem_max=26214400 net.core.rmem_max=26214400`
- **Persistence**: Added to `/etc/sysctl.d/99-cloudflared.conf`

#### Port Conflicts
- **Issue**: Services crashing due to port conflicts (e.g., AirPlay on port 5000)
- **Fix**: Disable conflicting services or change ports
- **Check**: `sudo lsof -i :PORT` or `sudo ss -tulpn | grep :PORT`

## Mobile "File Download" Issue

### Symptoms
- Mobile browsers attempting to download blank files instead of loading pages
- White screens on mobile devices

### Root Cause
- `encode gzip` in Caddyfile breaks mobile streaming for media servers
- Compression conflicts with mobile browser handling

### Fix
- Remove `encode gzip` from Jellyfin, Vaultwarden, and Paperless blocks in Caddyfile
- Restart Caddy: `docker compose restart caddy`

## Recovery Commands

If services go down:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-external-access.sh"
```

Verify services:
```bash
./scripts/verify-services.sh
```

