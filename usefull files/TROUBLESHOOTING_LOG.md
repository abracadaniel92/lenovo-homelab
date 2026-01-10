# Troubleshooting Log & Known Issues

This log documents specific issues encountered on the server and their fixes.

## [2026-01-10] Mattermost Installation & Configuration

**Date:** 2026-01-10
**Service:** Mattermost Team Communication Platform

### Initial Installation
**Completed:**
- Created Mattermost docker-compose.yml with PostgreSQL 15 database
- Configured for local-only access initially on port 8065
- Set up proper volume persistence for data, config, logs, and plugins
- Created comprehensive README.md with setup instructions

**Configuration Details:**
- Port: 8065 (mapped to host)
- Database: PostgreSQL 15 (separate container)
- Storage: Local filesystem (Docker volumes)
- Authentication: Email/password enabled

### External Exposure Setup
**Completed:**
- Added Caddyfile entry for `mattermost.gmojsoski.com` → `http://172.17.0.1:8065`
- Added Cloudflare Tunnel ingress rule: `mattermost.gmojsoski.com` → `http://localhost:8080`
- Updated Mattermost SITEURL to `https://mattermost.gmojsoski.com`
- Added domain to verify-services.sh script
- Created admin user via API: username `admin`, password `TempPass123!`
- Created initial team "Main Team" via API

**Issues Encountered:**

1. **Caddyfile Configuration Location:**
   - **Issue:** Mattermost routing not working - requests falling through to default portfolio site
   - **Root Cause:** Added Mattermost block to repo Caddyfile at `docker/caddy/Caddyfile`, but production Caddyfile is at `/home/docker-projects/caddy/config/Caddyfile`
   - **Fix:** Added Mattermost block to production Caddyfile at `/home/docker-projects/caddy/config/Caddyfile`
   - **Lesson:** Always check where Docker volumes mount config files vs repo copies

2. **Health Check Failure:**
   - **Issue:** Container marked as "unhealthy" due to default healthcheck using `mmctl system status --local`
   - **Root Cause:** Healthcheck requires local mode enabled, but we disabled it for external access (`MM_SERVICESETTINGS_ENABLELOCALMODE: false`)
   - **Fix:** Updated healthcheck to use process check: `pgrep -f mattermost || exit 1`
   - **Status:** Mattermost is functional despite healthcheck showing "starting" - API responds correctly

3. **Sign-In Methods Disabled:**
   - **Issue:** Users couldn't log in - "This server doesn't have any sign-in methods enabled"
   - **Root Cause:** Email authentication was disabled in initial config (set for local-only)
   - **Fix:** Enabled email authentication:
     - `MM_EMAILSETTINGS_ENABLESIGNUPWITHEMAIL: true`
     - `MM_EMAILSETTINGS_ENABLESIGNINWITHEMAIL: true`
     - `MM_SERVICESETTINGS_ENABLEOPENSERVER: true` (for initial account creation)

4. **Team Creation Required:**
   - **Issue:** After login, Mattermost required team selection but no teams existed
   - **Fix:** Created "Main Team" via Mattermost API using admin authentication
   - **Method:** Used login token from response header (`Token:` header) for API authentication

5. **DNS Propagation Delay:**
   - **Issue:** External DNS not resolving immediately after CNAME creation
   - **Solution:** Waited for DNS propagation (5-15 minutes). External DNS resolvers (8.8.8.8, 1.1.1.1) resolved correctly, local Pi-hole DNS took longer to update

6. **Local Network Access Issue:**
   - **Issue:** Mattermost not accessible locally via domain name (`http://mattermost.gmojsoski.com`)
   - **Root Cause:** Browsers default to port 80 for HTTP, but Caddy listens on port 8080 on the host (mapped from container port 80). Pi-hole DNS correctly resolves to local IP (192.168.1.97), but port 80 has no listener.
   - **Solution:** For local HTTP access via domain, users must specify port 8080: `http://mattermost.gmojsoski.com:8080`
   - **Alternative Access Methods:**
     - HTTPS: `https://mattermost.gmojsoski.com` (goes through Cloudflare Tunnel - works fine)
     - Direct IP:port: `http://192.168.1.97:8065` (bypasses Caddy, always works, no DNS needed)
     - Localhost: `http://localhost:8065` (from server itself)
   - **Note:** This is expected behavior - Caddy is intentionally on port 8080 to avoid conflicts. All services follow this pattern.
   - **About nginx:** Nginx is NOT required. Mattermost works fine with Caddy directly. Some older guides mention nginx, but it would be redundant.

7. **Pi-hole IPv6 DNS Resolution Issue (PENDING FIX ON PI-HOLE DEVICE):**
   - **Issue:** `nslookup mattermost.gmojsoski.com` returns both local IPv4 (192.168.1.97) AND Cloudflare IPv6 addresses (2606:4700:...). Browsers prefer IPv6, causing connections to go through Cloudflare instead of directly to local server.
   - **Root Cause:** Pi-hole forwards DNS queries upstream even when a Local DNS Record exists. The Local DNS Record creates an A record (IPv4), but Pi-hole still forwards AAAA (IPv6) queries upstream to Cloudflare DNS, resulting in both IPv4 and IPv6 addresses being returned.
   - **Impact:** When accessing `http://mattermost.gmojsoski.com:8080` locally, browsers may try IPv6 first, routing through Cloudflare instead of direct local access, causing slower/indirect connections.
   - **Workaround (Currently in use):** Access Mattermost directly via IP: `http://192.168.1.97:8065` (bypasses DNS, always works)
   - **Solution (To be implemented on Pi-hole device):**
     - **Option 1 (Recommended):** Disable IPv6 in Pi-hole Admin UI:
       - Access `http://192.168.1.98/admin` (or Pi-hole IP)
       - Settings → DNS → Uncheck "Enable IPv6 support"
       - Save and restart Pi-hole: `docker restart pihole`
     - **Option 2:** Create custom dnsmasq config on Pi-hole device:
       - Create file: `/etc/dnsmasq.d/99-block-ipv6-local-domains.conf`
       - Add: `server=/mattermost.gmojsoski.com/#` (and other local domains)
       - This prevents Pi-hole from forwarding AAAA queries upstream for these domains
       - See template: `docker/pihole/99-block-ipv6-local-domains.conf`
   - **Verification:** After fix, `nslookup mattermost.gmojsoski.com` should show ONLY `192.168.1.97` (no IPv6 addresses)
   - **Testing:** Health check system (`enhanced-health-check.timer`) was disabled to test correlation - **CONFIRMED: NOT RELATED**. The IPv6 DNS issue persists even with health check disabled, confirming it's a Pi-hole configuration issue, not health check related.
   - **Status:** PENDING - To be fixed on Raspberry Pi (Pi-hole device) by user
   - **Note:** This issue affects ALL services with Local DNS Records in Pi-hole (Jellyfin, Nextcloud, etc.), not just Mattermost. The fix will apply to all services.

### Known Issues / Stability Concerns
**Reported:** Service appears "a bit unstable" and drops from time to time

**Potential Causes to Monitor:**
- Health check configuration may need refinement
- Resource constraints (Mattermost + PostgreSQL on same host)
- Network connectivity issues
- Database connection pool exhaustion

**Recommendations for Stability:**
- Monitor logs: `docker compose logs -f mattermost`
- Check container resource usage: `docker stats mattermost mattermost-postgres`
- Verify database connection health
- Consider adjusting healthcheck interval/start_period if startup is slow
- Monitor Mattermost application logs for errors: `/mattermost/logs/`

### Files Modified/Created:
- `docker/mattermost/docker-compose.yml` (created)
- `docker/mattermost/README.md` (created)
- `docker/mattermost/fix-auth.sh` (created - helper script, not used)
- `/home/docker-projects/caddy/config/Caddyfile` (added Mattermost block - production file)
- `docker/caddy/Caddyfile` (added Mattermost block - repo copy)
- `Makefile` (added `lab-mattermost-*` commands)
- `restart services/LAB_COMMANDS.md` (added Mattermost commands)
- `scripts/verify-services.sh` (added `mattermost.gmojsoski.com`)
- `README.md` (added Mattermost to services list)
- `~/.cloudflared/config.yml` (added Mattermost ingress - production file, not in repo)

### Commands Added to Makefile:
- `make lab-mattermost` - Show help
- `make lab-mattermost-start` - Start Mattermost
- `make lab-mattermost-stop` - Stop Mattermost
- `make lab-mattermost-restart` - Restart Mattermost
- `make lab-mattermost-logs` - View logs
- `make lab-mattermost-status` - Check status

### Access Information:
- **External URL:** https://mattermost.gmojsoski.com
- **Local URL:** http://localhost:8065
- **Admin Username:** admin
- **Admin Email:** admin@gmojsoski.com
- **Initial Password:** TempPass123! (CHANGE THIS!)
- **Default Team:** Main Team

### Next Steps (Future Improvements):
1. ✅ Change default admin password after first login
2. ✅ Monitor stability and investigate drops
3. Consider enabling SMTP for email notifications
4. Set up backup strategy for Mattermost database
5. Configure team permissions and policies
6. Add Mattermost to backup scripts if needed

## [2026-01-07] Cloudflare Tunnel Certificate Configuration Error

**Symptoms:**
- Cloudflare tunnel replicas showing error: `ERR Cannot determine default origin certificate path`
- Error appeared in logs but tunnel was still functioning
- Both replicas (cloudflared-1 and cloudflared-2) showing the same error on startup

**Root Cause:**
- The `cert.pem` file exists at `/home/goce/.cloudflared/cert.pem` on the host
- Docker containers mount the directory but cloudflared couldn't find the certificate in default search paths
- Config file didn't explicitly specify the `origincert` path

**Fix:**
- Added `origincert: /home/goce/.cloudflared/cert.pem` to `~/.cloudflared/config.yml`
- Restarted tunnel containers: `cd /home/docker-projects/cloudflared && docker compose restart`
- Verified in logs: Settings now show `origincert:/home/goce/.cloudflared/cert.pem`
- Error eliminated from logs

**Verification:**
- External access working (HTTP 200)
- Both replicas running without certificate errors
- Tunnel connections established successfully

**Files Modified:**
- `/home/goce/.cloudflared/config.yml` - Added `origincert` line

## [2026-01-04] Service Down (502 Errors) after System Freeze

**Symptoms:**
- All services accessible internally and directly via Caddy.
- External access via Cloudflare Tunnel returning intermittent 502 errors (approx. 60% failure rate).
- Bookmarks service returning 502 permanently.

### Issue 1: Cloudflare Tunnel Instability
**Root Cause:**
- Multiple `cloudflared` replicas (2) running on host network were creating too many connections (8 total).
- UDP buffer sizes were too small (`net.core.wmem_max` & `rmem_max` = 212992), causing connection drops under load/instability.
- Logs showed: `ERR Request failed error="Incoming request ended abruptly: context canceled"` and `Application error 0x0` (QUIC packet loss).

**Fix:**
- Increased BOTH UDP buffer sizes to **25MB** (Overkill setting for stability).
- Command: `sudo sysctl -w net.core.wmem_max=26214400 net.core.rmem_max=26214400`
- Persistence: Added both settings to `/etc/sysctl.d/99-cloudflared.conf`.

### Issue 2: Bookmarks Service (Flask) Port Conflict
**Root Cause:**
- `shairport-sync` (AirPlay receiver) was starting on boot and claiming port **5000**.
- The Flask bookmarks service tries to bind to port 5000 and crashes if it's taken.
- Health check system didn't resolve this because it only checked if service was "active" (and crash-looping counts as activating).

**Fix:**
- Identified conflict using `sudo lsof -i :5000`.
- Disabled unused AirPlay service: `sudo systemctl disable --now shairport-sync`.
- Updated `enhanced-health-check.sh` to specifically check for port 5000 conflicts and kill unauthorized processes.

## General Recovery Commands

If 502 errors return, run the cleanup/recovery script:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-external-access.sh"
```

## [2026-01-04] Service Inaccessibility & Mobile "File Download" Issue

### 🔴 Symptoms
1.  **Global 502/503 Errors:** All services (`gmojsoski.com`, `jellyfin`, `cloud`, etc.) intermittently returning 502 Bad Gateway.
2.  **Persistent 404 on Jellyfin:** Even when Root domain worked, Jellyfin maintained a 404 (Cloudflare page).
3.  **Mobile Browsers "Downloading" file:** Instead of loading the Jellyfin/Vaultwarden login page, mobile browsers (Chrome/Safari) would attempt to download a blank file or show a white screen.
4.  **Health Check Fails:** Automated health check couldn't find the repair script.

### 🔍 Root Causes identified
1.  **Cloudflared Networking:** The `cloudflared` container runs in `network_mode: host`. Attempts to bind ingress rules to `127.0.0.1` or the LAN IP (`192.168.1.97`) caused instability and 502s due to loopback/interface quirks in this mode.
2.  **Ingress Mismatch (404):** The 404s were due to configuration drift where the running process held a different config state than the file on disk during debugging.
3.  **Mobile "Blank Page" (Compression):** Caddy was applying `encode gzip` to Jellyfin and Vaultwarden. These applications (and their mobile clients) often handle compressed initial handshakes poorly, or Cloudflare double-compression caused issues.
4.  **Missing SSL Signals:** Mobile clients were not receiving the `X-Forwarded-Ssl: on` header, causing them to treat the connection as insecure or improperly redirect.

### ✅ Fixes Applied
1.  **Ingress Configuration:** Reverted and locked `~/.cloudflared/config.yml` to use `http://localhost:8080` for ALL services. This is the correct way to address Caddy on the host when running in `network_mode: host`.
2.  **Robust Restart:** Updated `fix-external-access.sh` to use `docker compose down && docker compose up -d` instead of just `restart`. This forces a clean state.
3.  **Caddyfile Optimization:**
    *   **Disabled Gzip:** Removed `encode gzip` for `@jellyfin` and `@vault` blocks.
    *   **Added Headers:** Injected `header_up X-Forwarded-Ssl on` for these services.
4.  **Health Check:** Updated `/usr/local/bin/enhanced-health-check.sh` to match the repo version, fixing the path to the repair script.
5.  **Redundancy:** Confirmed `replicas: 2` in `docker-compose.yml` for Cloudflared.

### 🧪 Verification
*   `curl -I https://gmojsoski.com` -> **HTTP 200**
*   `curl -I https://jellyfin.gmojsoski.com/web/index.html` -> **HTTP 200** (was 302 loop/download)
*   **Mobile Test:** Validated login page loads correctly without downloading files.


## [2026-01-06] Paperless-ngx Addition Caused Global 502 Outage

### 🔴 Symptoms
1.  **Global 502/503 Errors:** After adding Paperless-ngx, external access to ALL services (Jellyfin, Nextcloud, etc.) began failing with 502 Bad Gateway.
2.  **Paperless CSRF Failed:** Paperless logs showed `Forbidden (403) CSRF verification failed. Request aborted.` and `DisallowedHost` errors.
3.  **Config Drift:** `~/.cloudflared/config.yml` was found to have reverted to `127.0.0.1` instead of `localhost`.

### 🔍 Root Causes identified
1.  **Configuration Reversion:** Some process or manual edit reverted `~/.cloudflared/config.yml` ingress rules from `http://localhost:8080` (stable) to `http://127.0.0.1:8080` (unstable on this host setup). This caused the Cloudfared tunnel to lose connectivity to Caddy intermittently.
2.  **Over-Engineering Caddy:** The initial Caddyfile entry for Paperless included unnecessary headers (`X-Forwarded-Host`, `Host`) that conflicted with the reverse proxy flow, causing CSRF validation in Django (Paperless) to fail.
3.  **Missing SSL Header:** Initially missing `X-Forwarded-Ssl: on` caused redirect loops.

### ✅ Fixes Applied
1.  **Simplified Caddy Config:** Removed all manual header overrides from the Paperless Caddy block. Used the standard `reverse_proxy` directive.
    ```caddyfile
    handle @paperless {
        reverse_proxy http://172.17.0.1:8097
    }
    ```
2.  **Enforced Localhost:** Reverted `~/.cloudflared/config.yml` to use `http://localhost:8080` for the Paperless ingress rule and all other services.
3.  **Integrity Check:** Added `check_config_integrity` function to `enhanced-health-check.sh` to automatically detect and fix if the config reverts to `127.0.0.1` again.
4.  **Service Verification:** Created `scripts/verify-services.sh` to quickly validate HTTP 200/302 status for all subdomains.

### 🧪 Verification
*   Paperless now accessible at `https://paperless.gmojsoski.com` (HTTP 200).
*   All other services restored.
*   Mobile access confirmed.

## [2026-01-08] Mobile Download/Blank Page Issue - Health Check Gap

### 🔴 Symptoms
1. **Mobile browsers downloading .txt files** instead of rendering pages for Jellyfin, Paperless, Tickets, Cloud
2. **Services returning HTTP 200/302** (appearing healthy to health check)
3. **Desktop/WiFi working fine** - only mobile network affected
4. **Issue persisted after Cloudflare cache purge**

### 🔍 Root Causes Identified
1. **Caddyfile Configuration Drift:** `encode gzip` was re-added to mobile-sensitive services (Jellyfin, Paperless, Tickets, Cloud)
2. **Cloudflare Double-Compression:** Caddy compresses → Cloudflare compresses again → Mobile browsers get confused
3. **Health Check Limitation:** Script only checks HTTP status codes (200/302), not:
   - Content-Type headers
   - Compression settings
   - Mobile browser compatibility
   - Caddyfile configuration integrity

### ✅ Fixes Applied
1. **Removed `encode gzip`** from mobile-sensitive services:
   - `@jellyfin` - removed gzip, kept `X-Forwarded-Ssl on`
   - `@paperless` - removed gzip, added `X-Forwarded-Ssl on`
   - `@tickets` - removed gzip, added `X-Forwarded-Ssl on`
   - `@cloud` - removed gzip, simplified headers
2. **Removed problematic headers:** `Host` and `X-Forwarded-Host` (Caddy handles these automatically)
3. **Added Caddyfile integrity check** to `enhanced-health-check.sh`:
   - Warns if `encode gzip` detected in mobile-sensitive service blocks
   - Prevents silent configuration drift
4. **Scaled Cloudflare tunnel to 1 replica** (reduced complexity)

### 🧪 Verification
*   All services returning HTTP 200/302 ✅
*   Mobile browsers now render pages correctly ✅
*   Health check now monitors Caddyfile configuration ✅

### 📝 Lessons Learned
- **Health checks must validate configuration, not just status codes**
- **Mobile clients are more sensitive to compression issues than desktop**
- **Cloudflare edge caching can persist issues even after server fixes**
- **Configuration drift detection is critical for preventing regressions**

### 🔧 Prevention
- Health check now includes `check_caddyfile_integrity()` function
- Monitors for `encode gzip` in: `@jellyfin`, `@paperless`, `@vault`, `@tickets`, `@cloud`
- Logs warnings when problematic config detected (requires manual fix to ensure proper headers)
