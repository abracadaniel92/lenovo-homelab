# Emergency Service Restore

**Date**: December 28, 2025

## Quick Fix Commands

If everything is down, run these in order:

### 1. Restart All Services
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"
```

### 2. Restart Cloudflare Tunnel
```bash
sudo systemctl restart cloudflared.service
```

### 3. Restart Caddy
```bash
docker restart caddy
```

### 4. Check Status
```bash
# Check systemd services
systemctl status cloudflared.service gokapi.service bookmarks.service planning-poker.service

# Check Docker containers
docker ps

# Test local access
curl http://localhost:8080
curl http://localhost:3000
curl http://localhost:5000
curl http://localhost:8091
```

## What Happened

Recent changes to Caddyfile may have caused brief interruptions during reload. All services are running locally, but public access requires Cloudflare tunnel to be running.

## Current Status

- ✅ All Docker containers: Running
- ✅ All systemd services: Running  
- ✅ Caddy: Running and configured correctly
- ⚠️ Cloudflare tunnel: May need restart

## Verification

After running the commands above, test:
```bash
curl -I https://gmojsoski.com
curl -I https://poker.gmojsoski.com
curl -I https://files.gmojsoski.com
curl -I https://bookmarks.gmojsoski.com
```

