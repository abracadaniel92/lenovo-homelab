# External Access Failure Investigation - January 2, 2026

## 🔴 Root Cause Identified

### Primary Issue: Misconfigured Health Check Script

**Problem:**
- Health check script at `/usr/local/bin/enhanced-health-check.sh` is checking for `cloudflared.service` (systemd service)
- Cloudflare tunnel actually runs as **Docker containers** (`cloudflared-cloudflared-1` and `cloudflared-cloudflared-2`)
- Systemd service does NOT exist: `Unit cloudflared.service could not be found`

**Impact:**
- Health check detects tunnel as "not running" every 30 seconds
- Logs show constant errors: `ERROR: Cloudflare tunnel not running. Restarting...` since 08:14:47
- Script tries to restart non-existent service repeatedly
- This creates false alarms and potential instability

---

## Timeline of Events

### Midnight Event (23:43:57 - January 1, 2026)
- **Both Cloudflare tunnel containers restarted** simultaneously
  - `cloudflared-cloudflared-1`: Started at `2026-01-01T23:43:57.154720895Z`
  - `cloudflared-cloudflared-2`: Started at `2026-01-01T23:43:57.155641314Z`
- **Caddy also restarted** around the same time (8 hours ago, 21 hours since container created)

### What Happened:
1. **Containers disconnected and reconnected** (logs show connection termination and retry)
2. **During restart window** (~30-60 seconds), external access was unavailable
3. **Tunnels successfully reconnected** to Cloudflare edge servers
4. **Services are now accessible** (verified at 08:24:51)

---

## Current Status ✅

### Services Running:
- ✅ **Cloudflare Tunnel**: 2 replicas running (healthy)
- ✅ **Caddy**: Running and responding
- ✅ **Jellyfin**: Running (healthy)
- ✅ **All services**: Accessible locally

### External Access:
- ✅ **Working**: `https://jellyfin.gmojsoski.com` returns HTTP 302 (redirect)
- ✅ **DNS**: Resolving correctly to Cloudflare IPs
- ✅ **Tunnel**: Connected to Cloudflare edge (4 active connections)

### Metrics:
- Tunnel 1: 909 requests proxied
- Tunnel 2: 7,939 requests proxied
- Both tunnels registered and active

---

## Investigation Findings

### 1. **Not a Dynamic IP Issue** ❌
- **Public IP**: `77.28.191.158` (current, likely unchanged)
- **Private IP**: `192.168.1.97` (static lease, confirmed)
- **IP changes don't affect Cloudflare Tunnel** - it works regardless of public IP

### 2. **Not a DNS Issue** ❌
- DNS resolves correctly to Cloudflare IPs: `172.67.205.31`, `104.21.22.141`
- DNS is working as expected

### 3. **Root Cause: Container Restart + Health Check Misconfiguration** ✅

**Why containers restarted at midnight:**
- Possible causes:
  1. **Network hiccup** - Brief disconnection triggered reconnection
  2. **Health check interference** - Misconfigured health check may have attempted restart
  3. **Docker daemon restart** - Unlikely (no logs)
  4. **Resource pressure** - Possible but unlikely

**Health Check Issue:**
```bash
# Current (WRONG) health check logic:
if ! systemctl is-active --quiet cloudflared.service; then
    log "ERROR: Cloudflare tunnel not running. Restarting..."
    sudo systemctl restart cloudflared.service
fi

# Should be (CORRECT):
TUNNEL_RUNNING=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" | wc -l)
if [ "$TUNNEL_RUNNING" -lt 1 ]; then
    log "ERROR: Cloudflare tunnel not running. Restarting..."
    cd /home/docker-projects/cloudflared
    docker compose up -d
fi
```

---

## Issues Found

### 1. Health Check Script Mismatch
- **Repository version**: Correctly checks Docker containers
- **Installed version** (`/usr/local/bin/enhanced-health-check.sh`): Checks non-existent systemd service
- **Fix needed**: Update installed script to match repository version

### 2. Health Check Logging False Positives
- Logs show constant errors since 08:14:47
- False alarms due to checking wrong service type
- Creates noise and potential instability

### 3. Possible Network Stability
- Containers restarted simultaneously (indicating external trigger)
- May need to investigate network stability
- Consider adding better reconnection handling

---

## Recommended Fixes

### Fix 1: Update Health Check Script (CRITICAL)

The installed health check script needs to be updated to check Docker containers instead of systemd service:

```bash
# Backup current script
sudo cp /usr/local/bin/enhanced-health-check.sh /usr/local/bin/enhanced-health-check.sh.backup

# Update script from repository version
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/enhanced-health-check.sh" /usr/local/bin/enhanced-health-check.sh

# Verify it's correct
sudo grep -A 5 "Cloudflare Tunnel" /usr/local/bin/enhanced-health-check.sh
```

### Fix 2: Verify Health Check Logic

Ensure the script checks Docker containers:
```bash
TUNNEL_RUNNING=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" | wc -l)
if [ "$TUNNEL_RUNNING" -lt 1 ]; then
    log "ERROR: Cloudflare tunnel not running. Restarting..."
    cd /home/docker-projects/cloudflared
    docker compose up -d
fi
```

### Fix 3: Add Better Reconnection Handling

Consider adding exponential backoff for tunnel restarts and verification that tunnel is actually connected before marking as healthy.

### Fix 4: Monitor Network Stability

- Add monitoring for network disconnections
- Track tunnel reconnection frequency
- Alert if reconnections happen too frequently

---

## Verification Steps

### Check External Access:
```bash
curl -I https://jellyfin.gmojsoski.com
# Should return: HTTP/2 302 or 200
```

### Check Tunnel Status:
```bash
docker ps | grep cloudflared
# Should show 2 containers running

docker logs cloudflared-cloudflared-1 --tail 20
# Should show "Registered tunnel connection"
```

### Check Health Check Logs:
```bash
tail -20 /var/log/enhanced-health-check.log
# Should NOT show constant "ERROR: Cloudflare tunnel not running"
```

---

## Conclusion

**Services are currently accessible and working correctly.**

The issue at midnight was caused by:
1. Simultaneous restart of Cloudflare tunnel containers
2. Brief disconnection during restart window
3. Containers successfully reconnected

The health check misconfiguration is causing:
- False error logs
- Potential instability from incorrect restart attempts
- Needs to be fixed to prevent future issues

**Action Required**: Update health check script to properly detect Docker containers instead of checking for non-existent systemd service.

---

*Investigation completed: January 2, 2026 08:25 AM*
*Investigator: AI Assistant*
*System: lemongrab (192.168.1.97)*

