# How to Fix Cloudflare Tunnel 502 Error

## The Problem
- Cloudflared service is running ✓
- Caddy is working locally ✓
- Tunnel connections are established ✓
- But public endpoint returns 502 Bad Gateway ✗
- Tunnel metrics show 0 requests proxied

## Root Cause
The tunnel is connected but not forwarding requests. This is usually a **DNS or Cloudflare dashboard configuration issue**.

## Fix Steps

### Step 1: Check Cloudflare Dashboard

1. **Go to Cloudflare Dashboard**: https://dash.cloudflare.com
2. **Select your domain**: gmojsoski.com
3. **Go to Zero Trust** → **Networks** → **Tunnels**
4. **Find your tunnel**: "portfolio"
5. **Check status**: Should show "Healthy" (green)
6. **If not healthy**: Click on tunnel → Check for errors

### Step 2: Verify DNS Configuration

1. **Go to DNS** → **Records**
2. **Check gmojsoski.com record**:
   - Should be a **CNAME** record
   - Should point to: `<tunnel-id>.cfargotunnel.com`
   - Should have **Proxy status: Proxied** (orange cloud ☁️)
3. **If wrong**:
   - Edit the record
   - Type: CNAME
   - Name: @ (or gmojsoski.com)
   - Target: `<your-tunnel-id>.cfargotunnel.com`
   - Proxy: Proxied (orange cloud)
   - Save

### Step 3: Verify Tunnel Route Configuration

1. **In Zero Trust** → **Tunnels** → **portfolio**
2. **Go to "Public Hostname" tab** (or "Routes")
3. **Verify routes exist**:
   - Should have entries for:
     - gmojsoski.com
     - www.gmojsoski.com
     - analytics.gmojsoski.com
     - files.gmojsoski.com
     - cloud.gmojsoski.com
     - etc.
4. **Each route should point to**: `http://localhost:8080`

### Step 4: Restart Tunnel (After DNS Fix)

After fixing DNS, restart the tunnel:

```bash
sudo systemctl restart cloudflared.service
```

Wait 30-60 seconds, then test:
```bash
curl -I https://gmojsoski.com
```

### Step 5: If Still Not Working - Recreate Tunnel

If the above doesn't work, you may need to recreate the tunnel:

1. **Delete old tunnel in Cloudflare dashboard**
2. **Create new tunnel**:
   ```bash
   cloudflared tunnel create portfolio
   ```
3. **Update config.yml** with new tunnel ID
4. **Route domains**:
   ```bash
   cloudflared tunnel route dns portfolio gmojsoski.com
   cloudflared tunnel route dns portfolio www.gmojsoski.com
   # ... repeat for other domains
   ```
5. **Restart service**:
   ```bash
   sudo systemctl restart cloudflared.service
   ```

## Quick Diagnostic Commands

```bash
# Check tunnel status
systemctl status cloudflared.service

# Check tunnel connections
journalctl -u cloudflared.service | grep "Registered tunnel connection"

# Test local Caddy
curl -H "Host: gmojsoski.com" http://localhost:8080

# Test public endpoint
curl -I https://gmojsoski.com

# Check tunnel metrics
curl http://localhost:20241/metrics | grep tunnel_total_requests
```

## Common Issues

### Issue: DNS not pointing to tunnel
**Fix**: Update DNS record to point to `<tunnel-id>.cfargotunnel.com`

### Issue: Tunnel not routing domains
**Fix**: In Cloudflare dashboard, add public hostnames/routes for each domain

### Issue: Tunnel credentials expired
**Fix**: Re-authenticate or recreate tunnel

### Issue: Wrong service URL in config
**Fix**: Ensure config.yml has `service: http://localhost:8080` (not 127.0.0.1)

## Verification

After fixes, verify:
1. ✅ Tunnel shows "Healthy" in dashboard
2. ✅ DNS record points to tunnel
3. ✅ Public endpoint returns 200 (not 502)
4. ✅ Tunnel metrics show requests > 0

## Still Not Working?

1. Check Cloudflare status page: https://www.cloudflarestatus.com
2. Check tunnel logs: `journalctl -u cloudflared.service -f`
3. Test tunnel manually: `cloudflared tunnel --config ~/.cloudflared/config.yml run`
4. Contact Cloudflare support if tunnel shows errors in dashboard

