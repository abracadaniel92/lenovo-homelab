# Cloudflare Monitoring Guide

## Where to Monitor Cloudflare

### 1. Cloudflare Dashboard (Web UI) - **Primary Monitoring**

**URL:** https://dash.cloudflare.com/

**Steps:**
1. Log in to your Cloudflare account
2. Go to **Zero Trust** (or **Networks**)
3. Click on **Networks** > **Tunnels**
4. Select your tunnel (e.g., "portfolio")
5. View:
   - **Status**: Active/Inactive
   - **Connections**: Number of active connections
   - **Metrics**: Requests, bandwidth, errors
   - **Logs**: Real-time tunnel logs
   - **Health**: Connection health status

**What You Can See:**
- Tunnel connection status
- Request metrics (requests per second, bandwidth)
- Error rates
- Connection locations (data centers)
- Active ingress rules
- Health check status

### 2. Local Monitoring Commands

#### Check Tunnel Service Status
```bash
systemctl status cloudflared.service
```

#### View Real-Time Logs
```bash
# Follow logs in real-time
journalctl -u cloudflared.service -f

# View recent logs (last 50 lines)
journalctl -u cloudflared.service -n 50

# View logs since a specific time
journalctl -u cloudflared.service --since "1 hour ago"
```

#### Check if Tunnel Process is Running
```bash
pgrep -f cloudflared
ps aux | grep cloudflared
```

#### View Tunnel Configuration
```bash
cat ~/.cloudflared/config.yml
```

#### Check Tunnel Metrics (if enabled)
```bash
curl http://localhost:20241/metrics
```

### 3. Cloudflare Analytics Dashboard

**URL:** https://dash.cloudflare.com/

**Analytics Available:**
- **Analytics & Logs** > **Zero Trust**:
  - Network traffic
  - Request patterns
  - Error rates
  - Geographic distribution

- **Analytics** > **Web Traffic**:
  - Page views
  - Bandwidth usage
  - Request rates
  - Cache hit rates

### 4. Cloudflare Tunnel Metrics Endpoint

The tunnel runs a metrics server on `localhost:20241` (if enabled).

**Check if metrics are available:**
```bash
curl http://localhost:20241/metrics
```

**Metrics include:**
- Connection status
- Request counts
- Error counts
- Latency
- Bandwidth usage

### 5. Monitoring via Uptime Kuma

You can add Cloudflare tunnel as a monitor in Uptime Kuma:

1. Go to your Uptime Kuma instance
2. Add a new monitor
3. Type: **Keyword**
4. URL: `https://gmojsoski.com` (or any domain)
5. Keyword: `"gmojsoski"` or any unique text from your site
6. This will monitor if the tunnel is working

### 6. Quick Status Check Script

Create a simple monitoring script:

```bash
#!/bin/bash
# cloudflare-status.sh

echo "=== Cloudflare Tunnel Status ==="
echo ""

# Service status
echo "Service Status:"
systemctl is-active cloudflared.service && echo "✅ Active" || echo "❌ Inactive"

# Process check
if pgrep -f cloudflared > /dev/null; then
    echo "✅ Process running (PID: $(pgrep -f cloudflared))"
else
    echo "❌ Process not found"
fi

# Recent errors
echo ""
echo "Recent Errors (last 10):"
journalctl -u cloudflared.service --since "10 minutes ago" | grep -i error | tail -10

# Connection status
echo ""
echo "Recent Connection Events:"
journalctl -u cloudflared.service --since "10 minutes ago" | grep -E "Registered|connection" | tail -5
```

Save as `~/cloudflare-status.sh` and make executable:
```bash
chmod +x ~/cloudflare-status.sh
```

### 7. Cloudflare API (Advanced)

You can also monitor via Cloudflare API:

```bash
# Get tunnel status via API
curl -X GET "https://api.cloudflare.com/client/v4/accounts/{account_id}/cfd_tunnel/{tunnel_id}" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json"
```

## Common Monitoring Tasks

### Check if Tunnel is Working
```bash
# Test external access
curl -I https://gmojsoski.com

# Check local routing
curl -H "Host: gmojsoski.com" http://localhost:8080/
```

### View Connection Issues
```bash
# View all errors
journalctl -u cloudflared.service | grep -i error

# View connection failures
journalctl -u cloudflared.service | grep -i "failed\|connection"
```

### Monitor Tunnel Health
```bash
# Watch logs in real-time
journalctl -u cloudflared.service -f

# Check for specific issues
journalctl -u cloudflared.service | grep -E "ERR|WRN"
```

## Recommended Monitoring Setup

1. **Cloudflare Dashboard** - Primary monitoring (web UI)
2. **Uptime Kuma** - Automated uptime monitoring
3. **Local logs** - Troubleshooting and debugging
4. **Status script** - Quick health checks

## Troubleshooting

If you see issues:

1. **Check service status:**
   ```bash
   systemctl status cloudflared.service
   ```

2. **View recent logs:**
   ```bash
   journalctl -u cloudflared.service -n 50
   ```

3. **Restart tunnel:**
   ```bash
   sudo systemctl restart cloudflared.service
   ```

4. **Check configuration:**
   ```bash
   cat ~/.cloudflared/config.yml
   ```

5. **Verify DNS in Cloudflare dashboard:**
   - Ensure CNAME records point to tunnel
   - Check DNS propagation

## Quick Links

- **Cloudflare Dashboard:** https://dash.cloudflare.com/
- **Zero Trust Tunnels:** https://one.dash.cloudflare.com/
- **Analytics:** https://dash.cloudflare.com/analytics

