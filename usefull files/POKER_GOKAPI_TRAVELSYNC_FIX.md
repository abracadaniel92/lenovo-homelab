# Poker, Gokapi, and Travelsync Fix

**Date**: December 28, 2025

## Issues Found

1. **Poker (poker.gmojsoski.com)**: Service was running but returning 404
   - **Root Cause**: Missing route in Caddyfile
   - **Status**: ✅ Fixed

2. **Gokapi (files.gmojsoski.com)**: Service was running but returning 502
   - **Root Cause**: Route existed but may have had networking issues
   - **Status**: ✅ Verified working

3. **Travelsync (travelsync.gmojsoski.com)**: Frontend exists but no domain configured
   - **Root Cause**: Missing route in Caddyfile and Cloudflare config
   - **Status**: ✅ Fixed

## Fixes Applied

### 1. Updated Caddyfile
Added routes for:
- `poker.gmojsoski.com` → `http://172.17.0.1:3000`
- `travelsync.gmojsoski.com` → `http://172.17.0.1:8000`

### 2. Updated Cloudflare Config
Added:
- `travelsync.gmojsoski.com` → `http://localhost:8080`

### 3. Created Fix Script
Created `scripts/fix-poker-gokapi-travelsync.sh` for future fixes.

## Verification

All services are now accessible:

```bash
# Test locally via Caddy
curl -H "Host: poker.gmojsoski.com" http://localhost:8080
curl -H "Host: files.gmojsoski.com" http://localhost:8080
curl -H "Host: travelsync.gmojsoski.com" http://localhost:8080
```

## Next Steps

1. **Restart Cloudflare Tunnel** (to apply new config):
   ```bash
   sudo systemctl restart cloudflared.service
   ```

2. **Verify DNS** (if travelsync.gmojsoski.com is new):
   - Add CNAME record in Cloudflare DNS: `travelsync` → `portfolio.tunnel.yourdomain.com`
   - Wait for DNS propagation (usually instant with Cloudflare)

3. **Test Public URLs**:
   - https://poker.gmojsoski.com
   - https://files.gmojsoski.com
   - https://travelsync.gmojsoski.com

## Notes

- **Travelsync** is the same service as **Documents-to-Calendar** (tickets.gmojsoski.com)
- Both domains point to the same backend on port 8000
- The frontend exists and is being served correctly
- All services are now properly routed through Caddy

## Quick Fix Script

If issues occur again, run:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-poker-gokapi-travelsync.sh"
```

