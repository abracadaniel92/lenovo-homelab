# Uptime Kuma - Cloudflared Monitoring Setup

Uptime Kuma can monitor cloudflared in several ways. Here are the recommended methods:

## Method 1: Monitor Cloudflared Metrics Endpoint (Recommended)

Cloudflared exposes a metrics endpoint on `localhost:20241/metrics`. You can monitor this:

1. **Access Uptime Kuma**: Open `http://localhost:3001` (or your Uptime Kuma URL)

2. **Add New Monitor**:
   - Click "Add New Monitor"
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: `Cloudflared Metrics`
   - **URL**: `http://localhost:20241/metrics`
   - **Interval**: 60 seconds (or your preference)
   - **Retry Interval**: 30 seconds
   - **Max Retries**: 3

3. **Advanced Settings**:
   - **Expected Status Code**: 200
   - **Expected Response Body**: Should contain "cloudflared" or metrics data
   - **Timeout**: 10 seconds

**Note**: This checks if cloudflared is running and responding, but it's only accessible from localhost. If Uptime Kuma is in a Docker container, you may need to use `host.docker.internal:20241/metrics` or the host's IP address.

## Method 2: Monitor Through Public Endpoint (Best for Real-World Status)

Monitor one of your public endpoints that goes through Cloudflare tunnel:

1. **Add New Monitor**:
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: `Cloudflared Tunnel (gmojsoski.com)`
   - **URL**: `https://gmojsoski.com`
   - **Interval**: 60 seconds
   - **Retry Interval**: 30 seconds
   - **Max Retries**: 3

2. **Advanced Settings**:
   - **Expected Status Code**: 200
   - **Follow Redirects**: Yes
   - **Timeout**: 15 seconds

This method checks if:
- Cloudflared tunnel is working
- Caddy is responding
- The entire chain (Cloudflare → Tunnel → Caddy → Site) is functional

## Method 3: Monitor Systemd Service Status (Requires Docker Socket)

Since Uptime Kuma has access to `/var/run/docker.sock`, you can use a Docker-based check:

1. **Add New Monitor**:
   - **Monitor Type**: Docker Container
   - **Friendly Name**: `Cloudflared Service`
   - **Container Name**: Check if cloudflared process is running
   - **Note**: This won't work directly since cloudflared is a systemd service, not a Docker container

**Alternative**: Create a simple HTTP endpoint that checks systemd status (requires a small script/service).

## Method 4: Monitor Multiple Endpoints (Comprehensive)

Set up monitors for:
1. **Cloudflared Metrics**: `http://localhost:20241/metrics` (checks cloudflared process)
2. **Main Site**: `https://gmojsoski.com` (checks full tunnel + Caddy)
3. **Caddy Direct**: `http://localhost:8080` (checks Caddy, bypasses tunnel)

## Recommended Setup

For best coverage, set up **Method 2** (public endpoint) as your primary monitor, as it checks the entire chain that users experience.

## Troubleshooting

### If metrics endpoint doesn't work from Docker:
- Use `host.docker.internal:20241/metrics` instead of `localhost:20241/metrics`
- Or use your host's IP address: `192.168.1.97:20241/metrics` (replace with your actual IP)

### To find your host IP:
```bash
hostname -I | awk '{print $1}'
```

### To verify metrics endpoint is accessible:
```bash
curl http://localhost:20241/metrics | head -20
```

## Integration with Health Check Script

Your existing health check script already monitors cloudflared.service. Uptime Kuma provides:
- Visual dashboard
- Alerting (email, Slack, etc.)
- Historical uptime data
- Public status page (optional)

Both systems complement each other:
- **Health Check Script**: Auto-restarts services
- **Uptime Kuma**: Monitors and alerts you when issues occur

