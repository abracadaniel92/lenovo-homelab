# Fix Subdomains Down - Quick Guide

## Problem
All subdomains returning 502/404 errors, but services are running locally.

## Quick Fix

### Option 1: Use the Fix Script
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
bash scripts/fix-subdomains-down.sh
```

### Option 2: Manual Fix (Faster)
```bash
# Restart Cloudflare Tunnel
sudo systemctl restart cloudflared.service

# Restart Caddy
docker restart caddy

# Wait a few seconds
sleep 5

# Check status
systemctl status cloudflared.service
docker ps | grep caddy
```

### Option 3: One-Liner
```bash
sudo systemctl restart cloudflared.service && docker restart caddy && echo "✅ Restarted. Wait 30-60 seconds for subdomains to come back online."
```

## What This Does

1. **Restarts Cloudflare Tunnel** - Reconnects to Cloudflare edge servers
2. **Restarts Caddy** - Refreshes reverse proxy routing
3. **Fixes routing** - Restores external access to all subdomains

## Expected Result

After 30-60 seconds, all subdomains should be accessible:
- ✅ gmojsoski.com
- ✅ tickets.gmojsoski.com
- ✅ poker.gmojsoski.com
- ✅ cloud.gmojsoski.com
- ✅ files.gmojsoski.com
- ✅ analytics.gmojsoski.com
- ✅ And all other subdomains

## If Still Not Working

1. Check Cloudflare tunnel logs:
   ```bash
   journalctl -u cloudflared.service -n 50 --no-pager
   ```

2. Check Caddy logs:
   ```bash
   docker logs caddy --tail 50
   ```

3. Test local access:
   ```bash
   curl -I http://localhost:8080
   ```

4. Test external access:
   ```bash
   curl -I https://gmojsoski.com
   ```

## Prevention

To prevent this from happening again, install permanent auto-recovery:
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
sudo bash scripts/permanent-auto-recovery.sh
```

