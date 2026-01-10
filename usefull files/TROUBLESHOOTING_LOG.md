# Troubleshooting Log & Known Issues

This log documents specific issues encountered on the server and their fixes.

## [2026-01-10] Mattermost → RocketChat → Zulip Migration

**Date:** 2026-01-10
**Action:** Mattermost removed → RocketChat attempted → Zulip installed

### Mattermost Removal
**Completed:**
- Stopped and removed Mattermost containers and volumes
- Removed Mattermost from Caddy configuration (both production and repo)
- Removed Mattermost from Cloudflare Tunnel config
- Removed Mattermost from Makefile commands
- Removed Mattermost from LAB_COMMANDS.md
- Removed Mattermost from verify-services.sh
- Removed Mattermost from main README
- Deleted Mattermost directory and all documentation

**Reason for Removal:**
- Intermittent 530/502 errors (root cause: failing health check + Caddy syntax error - both fixed but user opted for replacement)
- Service not accessible internally (DNS/IPv6 issues)
- User preference for alternative solution

### 🔍 Mattermost Failure Root Cause Analysis (Retrospective - 2026-01-10)

After investigating the WiFi access issue and fixing it, it's now clear what likely caused Mattermost to fail:

**Primary Root Cause: Same DNS Issue as WiFi Problem**
1. **Pi-hole Local DNS Record**: Pi-hole was configured with a Local DNS Record for `mattermost.gmojsoski.com` pointing to local server IP (`192.168.1.97`)
2. **Inconsistent Access Patterns**:
   - **WiFi devices** (using Pi-hole DNS): Resolved to local IP → tried to access locally → failed (Caddy not accessible on LAN, no HTTPS locally)
   - **Mobile devices**: Resolved to Cloudflare IP → went through tunnel → worked intermittently
   - **Server health checks**: May have been checking localhost or local IP, getting inconsistent results

**Secondary Issues:**
1. **IPv6 Conflicts**: Similar to other services, Pi-hole was returning both:
   - Local IPv4: `192.168.1.97` (from Local DNS Record)
   - Cloudflare IPv6: `2606:4700:...` (from upstream DNS)
   - Browsers preferred IPv6, causing unpredictable behavior

2. **Caddy Configuration Issues**:
   - Initial Caddy syntax error (mentioned as fixed, but timing suggests it contributed to problems)
   - Caddy only accessible on `localhost:8080`, not on LAN interface
   - No local HTTPS (Caddy has `auto_https off`)

3. **Health Check Failures**:
   - Health check script (`enhanced-health-check.sh`) checks HTTP status codes via external URLs
   - When WiFi devices resolved to local IP, health checks may have failed
   - Intermittent failures caused health check system to report Mattermost as unstable

4. **Intermittent 530/502 Errors**:
   - **530 errors**: Cloudflare-specific errors (tunnel connection issues, rate limiting)
   - **502 errors**: Bad Gateway (Caddy couldn't reach Mattermost, or tunnel couldn't reach Caddy)
   - Pattern matches the WiFi access issue - worked sometimes (mobile/external) but not others (WiFi/local)

**What "Tried Everything" Likely Included:**
Based on the troubleshooting log and README documentation:
- ✅ Fixed Caddy syntax error
- ✅ Fixed health check configuration
- ✅ Attempted DNS configuration changes
- ✅ Tested webhook connectivity (ntfy.sh intermittent 530 errors)
- ✅ Configured Pi-hole DNS records
- ✅ Tried IPv6 disabling (mentioned in README)
- ❌ **Did NOT remove Pi-hole Local DNS Record** (same solution as WiFi fix)

**Solution That Would Have Worked:**
The same solution that fixed WiFi access would have fixed Mattermost:
1. Remove Pi-hole Local DNS Record for `mattermost.gmojsoski.com`
2. Let all devices (WiFi and mobile) use Cloudflare DNS
3. All requests go through Cloudflare Tunnel consistently
4. No local network access issues
5. Consistent behavior across all networks

**Why It Wasn't Obvious:**
- Multiple symptoms (530/502 errors, health check failures, DNS issues) made it hard to identify single root cause
- Health check and Caddy syntax errors were genuine issues that masked the underlying DNS problem
- Intermittent nature (worked on mobile, failed on WiFi) made it seem like multiple problems
- The pattern wasn't clear until we saw the same issue with other services (cloud.gmojsoski.com)

**Lesson Learned:**
When a service works on mobile/external but not on WiFi/local network, check:
1. **Pi-hole Local DNS Records** - Are they causing local IP resolution?
2. **IPv6 conflicts** - Is Pi-hole returning both local IPv4 and Cloudflare IPv6?
3. **Caddy accessibility** - Is Caddy reachable from LAN, or only localhost?
4. **Remove Local DNS Records** - For services using Cloudflare Tunnel, let all devices use Cloudflare DNS consistently

**Note:** Mattermost was removed before this root cause was identified. The same pattern was seen with other services and fixed by removing Pi-hole Local DNS Records.

## [2026-01-10] Mattermost Reinstallation - Successful Setup

**Date:** 2026-01-10
**Action:** Mattermost reinstalled using Zulip's proven configuration pattern

### ✅ Setup Completed
- Created Mattermost docker-compose.yml following Zulip's pattern
- Configured PostgreSQL 15 database (no AVX requirement)
- Port mapping: 8066 (host) → 8065 (container) to avoid conflict with RocketChat
- Added Mattermost to Caddyfile with proper headers (no gzip - prevents real-time/webhook issues)
- Added Mattermost to Cloudflare Tunnel config
- Added Mattermost management commands to Makefile
- Updated verify-services.sh to include Mattermost
- Created comprehensive README with setup instructions and troubleshooting

### 🔧 Configuration Highlights
- **Port**: 8066 (host) → 8065 (container) - avoids RocketChat conflict on 8065
- **Database**: PostgreSQL 15 (no AVX requirement, compatible with CPU)
- **Access**: `https://mattermost.gmojsoski.com` via Cloudflare Tunnel
- **Caddy Config**: NO gzip encoding (like Zulip) - prevents real-time feature issues
- **DNS**: **NO Pi-hole Local DNS Record** - learned from previous WiFi access issues

### ✅ Verification
- **HTTP Status**: HTTP 200 ✅
- **Mattermost Version**: 11.2.1 (latest)
- **Container Status**: Running and healthy
- **Database**: PostgreSQL healthy
- **External Access**: Working via Cloudflare Tunnel
- **WiFi Access**: Working (no Pi-hole Local DNS Record - same fix as other services)

### 📝 Key Lessons Applied
1. **No Pi-hole Local DNS Records** - All devices use Cloudflare DNS for consistent access
2. **No gzip encoding** - Prevents issues with real-time features and webhooks (same as Zulip)
3. **Proper headers** - X-Forwarded-Proto, X-Forwarded-Ssl, Host headers configured
4. **Port conflict avoidance** - Used 8066 instead of 8065 (RocketChat is on 8065)

### 🚀 Management Commands
```bash
# From project root
make lab-mattermost-start    # Start Mattermost
make lab-mattermost-stop     # Stop Mattermost
make lab-mattermost-restart  # Restart Mattermost
make lab-mattermost-logs     # View logs
make lab-mattermost-status   # Check status
```

### 📍 Access URLs
- **External HTTPS**: `https://mattermost.gmojsoski.com` (recommended - all devices)
- **Local Direct**: `http://localhost:8066` (from server)

### ✅ Success Factors
- Used Zulip's proven configuration pattern
- Applied lessons learned from WiFi access issue (no Pi-hole Local DNS Record)
- Proper Caddy configuration (no gzip, correct headers)
- Correct port mapping to avoid conflicts
- Comprehensive documentation and troubleshooting guide

**Status**: ✅ Fully operational - Mattermost is up and running successfully

### RocketChat Installation & Removal
**Date:** 2026-01-10
**Service:** RocketChat Team Communication Platform

**Configuration Attempted:**
- Port: 3002 → 8065 (port conflicts resolved)
- Database: MongoDB 4.4 → 5.0 (AVX compatibility issues)
- RocketChat Version: Latest (7.12.2) → 6.6.4 (MongoDB 4.4 compatibility)
- Domain: `rocketchat.gmojsoski.com`

**Issues Encountered:**
- **CPU Compatibility**: Intel Pentium G4560T doesn't support AVX (required by MongoDB 5.0+)
- **MongoDB Version Conflict**: RocketChat 7.12.2 requires MongoDB 5.0+, but CPU can't run MongoDB 5.0+
- **Solution Attempted**: RocketChat 6.6.4 with MongoDB 4.4 (compatible versions)
- **Final Issue**: RocketChat 6.6.4 container stuck initializing, never fully started despite MongoDB being healthy

**Reason for Removal:**
- RocketChat container stuck in initialization loop (not crashing, but never completing startup)
- User requested alternative solution with better webhook support
- Zulip chosen as replacement (PostgreSQL-based, no AVX requirement, excellent webhook support)

**Files Removed:**
- RocketChat containers stopped (not deleted yet - can be cleaned up later)
- Configuration files updated to use Zulip instead

### Zulip Installation
**Date:** 2026-01-10
**Service:** Zulip Team Communication Platform

**Configuration:**
- Port: 8070 (host) → 80 (container), 8444 → 443
- Database: PostgreSQL 15 (no AVX requirement! ✅)
- Additional Services: Redis, RabbitMQ, Memcached
- Storage: Local filesystem (Docker volumes)
- Domain: `zulip.gmojsoski.com`

**Setup Completed:**
- Created Zulip docker-compose.yml with all dependencies (PostgreSQL, Redis, RabbitMQ, Memcached)
- Configured EXTERNAL_HOST to `zulip.gmojsoski.com`
- Added Caddy reverse proxy configuration (production and repo)
- Added Cloudflare Tunnel ingress rule
- Added to Makefile with `lab-zulip-*` commands
- Added to LAB_COMMANDS.md
- Added to verify-services.sh
- Created comprehensive README.md with webhook documentation

**Advantages:**
- ✅ **No AVX requirement** - Works on older CPUs
- ✅ **PostgreSQL-based** - Stable, well-supported database
- ✅ **Excellent webhook support** - Built-in webhook API, Slack-compatible
- ✅ **Threading model** - Unique topic-based organization
- ✅ **Active development** - Well-maintained open-source project

**Files Created/Modified:**
- `docker/zulip/docker-compose.yml` (created)
- `docker/zulip/README.md` (created)
- `/home/docker-projects/caddy/config/Caddyfile` (replaced RocketChat with Zulip block)
- `docker/caddy/Caddyfile` (replaced RocketChat with Zulip block - repo copy)
- `Makefile` (replaced `lab-rocketchat-*` with `lab-zulip-*` commands)
- `restart services/LAB_COMMANDS.md` (replaced RocketChat with Zulip commands)
- `scripts/verify-services.sh` (replaced `rocketchat.gmojsoski.com` with `zulip.gmojsoski.com`)
- `README.md` (updated to Zulip, removed RocketChat references)
- `~/.cloudflared/config.yml` (replaced RocketChat ingress with Zulip)

**Access Information:**
- **External HTTPS:** https://zulip.gmojsoski.com (via Cloudflare Tunnel)
- **Local Direct:** http://localhost:8070 (from server)
- **Local Network:** http://192.168.1.97:8070 (direct IP access)
- **Local Domain:** http://zulip.gmojsoski.com:8080 (via Caddy, requires DNS)

**Note:** Zulip's docker-zulip image may require initialization script on first start. Configuration provided is a starting point - may need adjustment based on actual docker-zulip image requirements.

**Next Steps:**
1. Start Zulip: `make lab-zulip-start`
2. Wait 2-5 minutes for initialization (database setup, migrations)
3. Access `https://zulip.gmojsoski.com` or `http://localhost:8070`
4. Complete setup wizard (create organization, admin account)
5. Configure webhooks via Admin panel → Integrations → Webhooks

**Final Status:** RocketChat removed due to initialization issues. Replaced with Zulip.

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

## [2026-01-10] WiFi Access Issue - Services Accessible on Mobile Network but Not WiFi

### 🔴 Symptoms
1. **Services work on mobile network**: `cloud.gmojsoski.com` and other services accessible via HTTPS on mobile data
2. **Services fail on WiFi**: Same services return connection errors or cannot be accessed on WiFi network
3. **DNS resolution difference**: `nslookup` shows both local IP (192.168.1.97) and Cloudflare IPv6 addresses

### 🔍 Root Cause Identified
1. **Pi-hole Local DNS Records**: Pi-hole is configured with Local DNS Records that resolve `*.gmojsoski.com` domains to local server IP (`192.168.1.97`)
2. **Caddy Network Configuration**: Caddy is only accessible on `localhost:8080` (host network), not exposed on LAN interface
3. **No Local HTTPS**: Caddy has `auto_https off`, so there's no SSL certificate for local access
4. **Network Behavior Difference**:
   - **WiFi (using Pi-hole)**: DNS resolves to local IP → client tries HTTPS on local IP → fails (no SSL listener)
   - **Mobile network**: DNS resolves to Cloudflare IP → goes through Cloudflare Tunnel → works correctly

### ✅ Solution
**Remove Local DNS Records from Pi-hole** for all `*.gmojsoski.com` domains that use Cloudflare Tunnel. This ensures:
- All devices (WiFi and mobile) use Cloudflare DNS
- All requests go through Cloudflare Tunnel consistently
- No local network access issues

**Steps to Fix:**
1. **Access Pi-hole Admin**: `http://192.168.1.98/admin` (or your Pi-hole IP)
2. **Navigate to**: Local DNS → DNS Records
3. **Remove entries** for:
   - `cloud.gmojsoski.com`
   - `jellyfin.gmojsoski.com`
   - `paperless.gmojsoski.com`
   - `bookmarks.gmojsoski.com`
   - `tickets.gmojsoski.com`
   - `poker.gmojsoski.com`
   - `files.gmojsoski.com`
   - `analytics.gmojsoski.com`
   - `vault.gmojsoski.com`
   - `shopping.gmojsoski.com`
   - `zulip.gmojsoski.com`
   - Any other `*.gmojsoski.com` subdomains
4. **Save changes** (Pi-hole reloads DNS automatically)
5. **Clear DNS cache** on WiFi devices:
   - Linux: `sudo systemd-resolve --flush-caches`
   - Windows: `ipconfig /flushdns`
   - Android: Toggle WiFi off/on or restart device
6. **Verify**: `nslookup cloud.gmojsoski.com` should now show only Cloudflare IPs (no local IP)

### 🧪 Verification
- WiFi devices can now access `https://cloud.gmojsoski.com` ✅
- Mobile devices continue to work ✅
- Consistent behavior across all networks ✅

### 📝 Note
If you want local network access (bypassing Cloudflare Tunnel), you would need to:
1. Configure Caddy to listen on LAN interface (not just localhost)
2. Set up proper SSL certificates for local access
3. Or use explicit port `http://cloud.gmojsoski.com:8080` (but browsers prefer HTTPS)

**Recommendation**: Remove Pi-hole Local DNS Records and use Cloudflare Tunnel for all access. This provides:
- Consistent behavior across networks
- Better security (Cloudflare DDoS protection)
- SSL termination handled by Cloudflare
- No local network configuration needed
