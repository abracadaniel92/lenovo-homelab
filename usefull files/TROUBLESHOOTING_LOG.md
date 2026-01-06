# Troubleshooting Log & Known Issues

This log documents specific issues encountered on the server and their fixes.

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
