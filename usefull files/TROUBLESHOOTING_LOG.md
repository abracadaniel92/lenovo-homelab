# Troubleshooting Log & Known Issues

This log documents specific issues encountered on the server and their fixes.

## [2026-04-26] Android emulator + ws-scrcpy service addition (local only)

**Date:** 2026-04-26  
**Action:** Added Docker-based Android emulator stack with browser control via ws-scrcpy. **Local/LAN access only** — no Cloudflare tunnel or Caddy reverse proxy. Public exposure was deliberately skipped (no `android.gmojsoski.com`).  
**Storage:** Persistent emulator data and ADB keys under `/home/docker-projects/android-emulator/` (root filesystem avoided per storage rules).  
**Changes:**  
- **docker/android-emulator/docker-compose.yml:** New stack — `halimqarroum/docker-android:api-33-playstore` (KVM-accelerated, Play Store image) and `shmayro/scrcpy-web` (`ws-scrcpy`) on host port `8233`. ADB exposed only on `127.0.0.1:5555`.  
- **docker/android-emulator/.env.example:** Runtime tunables (image variant, memory/cores, animation flags, storage paths).  
- **docker/android-emulator/README.md:** Start, access, iOS-via-LAN usage notes, optional APK export script.  
- **README.md:** Added Android Emulator (`<device-ip>:8233`) to running services table and directory tree.
**Access:**  
- Browser (server): `http://localhost:8233`  
- Browser (LAN devices, incl. iOS Safari): `http://<device-ip>:8233`  
- ADB (host only): `adb connect 127.0.0.1:5555`
**Notes:**  
- Requires `/dev/kvm`. First boot can take several minutes; recommended ≥ 8 GB RAM.  
- If you later want public access, the standard service-addition checklist applies: add a Caddy `@android_emulator` block, add `android.gmojsoski.com` to `cloudflare/config.yml`, and add the subdomain to `scripts/verify-services.sh`.

---

## [2026-04-23] Stirling PDF local-only deployment (1TB internal SSD)

**Date:** 2026-04-23  
**Action:** Added Stirling PDF as a Docker service for local/LAN access only (no Cloudflare subdomain).  
**Storage:** Persistent paths mapped to internal 1TB SSD under `/mnt/ssd_1tb/stirling-pdf/`.  
**Changes:**  
- **docker/stirling-pdf/docker-compose.yml:** New service using `stirlingtools/stirling-pdf:latest`, `restart: unless-stopped`, host port `8095:8080`.  
- **Volumes:** `/mnt/ssd_1tb/stirling-pdf/{trainingData,config,customFiles,logs,pipeline}` mapped into container.  
- **docker/stirling-pdf/README.md:** Added local access and management instructions.  
- **README.md:** Added Stirling PDF to running services and directory tree.
**Result:** Service is available locally at `http://localhost:8095/login` and on LAN at `http://<server-ip>:8095/login`.

---

## [2026-03-27] System Boot Hangs Without USB HDDs Attached

**Date:** 2026-03-27  
**Action:** Added `nofail` to fstab for the mergerfs pool to allow system boot without USB HDDs.  
**Symptoms:** Unplugging the 1TB or 2TB USB drives could cause the OS to hang on boot or enter Emergency Mode because the `/mnt/storage` mergerfs pool depended on them without a `nofail` flag.  
**Fix:**  
- Checked `/etc/fstab` and verified individual USB HDDs already had the `nofail` flag.  
- Added `nofail` to the `fuse.mergerfs` entry (`/mnt/storage`) to prevent it from halting boot.  
**Result:** The system will gracefully timeout (90s) and continue booting into the OS even if the USB HDDs are unplugged.

---

## [2026-03-12] Actual Budget added (budget.gmojsoski.com)

**Date:** 2026-03-12  
**Action:** Installed Actual Budget (personal finance) with subdomain budget.gmojsoski.com.  
**Storage:** Data on NVMe at `/home/actual-budget` (per user preference).  
**Changes:**  
- **docker/actual-budget/**: docker-compose (port 5006, volume /home/actual-budget), README.  
- **Caddy:** `config.d/50-utilities.caddy` — `@budget` host budget.gmojsoski.com → reverse_proxy 172.17.0.1:5006.  
- **Cloudflare:** Added budget.gmojsoski.com to ingress in `cloudflare/config.yml`; applied to ~/.cloudflared and restarted Caddy + cloudflared.  
- **scripts/verify-services.sh:** Added budget.gmojsoski.com to SUBDOMAINS.  
- **README.md:** Actual Budget in services table and directory tree.  
**Result:** https://budget.gmojsoski.com live after config copy and Caddy/cloudflared restart.

---

## [2026-03-09] HDD monitoring, health-check interval, and deploy (session summary)

**Date:** 2026-03-09  
**Summary of changes made in this session:**

1. **Mattermost webhook for health alerts**  
   - Added `scripts/health_webhook_url` (user-provided URL).  
   - Added `**/health_webhook_url` to `.gitignore` so the URL is not committed.

2. **Health check timer: 3 min → 1 hour**  
   - Updated all references from “every 3 minutes” to “every hour”.  
   - Files: `scripts/permanent-auto-recovery.sh`, `scripts/fix-health-check-timer.sh`, `scripts/verify-health-check.sh`, README, `usefull files/MONITORING_AND_RECOVERY.md`, `usefull files/HEALTH_CHECK_STATUS.md`, `docs/reference/infrastructure-diagram.md`, `scripts/deploy-health-check.sh`, `restart services/LAB_COMMANDS.md`.  
   - On production, apply with: update `/etc/systemd/system/enhanced-health-check.timer` to `OnUnitActiveSec=1h`, then `sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer`.

3. **USB HDD SMART check – standalone daily run**  
   - **`scripts/hdd-health-check.sh`**: Wrapper that sources `health.d/40-disk-smart.sh`; uses `/var/log/hdd-health-check.log`.  
   - **`systemd/hdd-health-check.service`** and **`systemd/hdd-health-check.timer`**: Timer runs daily at 11:00.  
   - **`scripts/deploy-hdd-health-check.sh`**: Deploys script, module, webhook, and systemd units; derives repo path from script location.  
   - **`scripts/verify-health-check-interval.sh`**: Verifies enhanced-health-check timer interval and next run.  
   - HDD check runs **once per day** (not with the main health check). The “💾 USB HDDs health” Mattermost summary (status + space per disk) is sent **only on Sunday**; failure/warning alerts are sent immediately on any run.

4. **`health.d/40-disk-smart.sh`**  
   - Added per-disk space (used/free) and one summary line per disk (OK / pre-failure / FAILED / not mounted).  
   - Summary notification gated to Sunday 11:00 (day=7, hour=11, minute<5).

5. **`systemd/hdd-health-check.service` fix**  
   - Removed invalid `WantedBy=multi-user.target` from `[Unit]` (belongs only in `[Install]`).  
   - After pulling, re-copy to `/etc/systemd/system/` and run `sudo systemctl daemon-reload`.

**Production deploy (lemongrab):** Run from repo root: `sudo bash scripts/deploy-hdd-health-check.sh`.  
**HDD capacities (from docs):** disk1 = 1 TB, disk2 = 2 TB, disk_old = 500 GB (legacy).  
**SMART alerts observed:** disk1 (pending/offline uncorrectable), disk2 (reallocated sectors), disk_old (SMART FAILED) — back up data and plan replacement.

---

## [2026-03-11] Immich primary storage on 1TB SATA SSD

**Date:** 2026-03-11  
**Action:** Use the 1TB SATA SSD (/dev/sda, mounted at /mnt/ssd_1tb) as primary storage for Immich (healthiest drive).  
**Changes:**  
- **docker/immich/.env**: `UPLOAD_LOCATION=/mnt/ssd_1tb/immich-library` (if .env is tracked; otherwise set manually).  
- **scripts/migrate-immich-to-ssd1tb.sh**: Migrates existing library from /mnt/storage/immich-library to /mnt/ssd_1tb/immich-library (rsync), updates .env, restarts Immich.  
- **docker/immich/README.md**, **create-library-dirs.sh**: Default path now /mnt/ssd_1tb/immich-library.  
- **health.d/40-disk-smart.sh**: Added `/mnt/ssd_1tb` to monitored mounts so the primary SSD appears in the Sunday HDD health report.  
**On server:** Ensure /mnt/ssd_1tb is in fstab, then run `sudo bash scripts/migrate-immich-to-ssd1tb.sh` from repo root.

**Result:** Migration completed successfully. Immich library now on primary 1TB SSD (/mnt/ssd_1tb/immich-library). Same data kept on mergerfs as backup. Wikipedia no-pics (~50GB) download planned for later (on mergerfs or after confirming primary storage usage).

---

## [2026-03-08] Root disk space & SSD usage

**Date:** 2026-03-08  
**Context:** Root (/) was at 93%; health check alerts for Root and “SSD” both refer to the same partition (`/dev/nvme0n1p2` — root is 101G, and `/mnt/ssd` lives on that same partition).  
**SSD space:** Root partition has **~6.9 GB free** (89G used of 101G). There is no separate SSD partition; `/mnt/ssd` is on root.  
**To free root:** Run (requires sudo):  
- `sudo apt-get clean` — frees ~5 GB (apt package cache in `/var/cache/apt/archives`).  
- `sudo journalctl --vacuum-size=100M` — caps systemd journal at 100 MB (frees ~114 MB).  
- Optional: `sudo find /var/log -name "*.log" -mtime +30 -exec truncate -s 0 {} \;` to truncate old logs (use with care).  
**Note:** Docker data is already on `/home/docker-data` (not on root).

### What else can be moved from root

| What | Size (approx.) | How | Effort |
|------|-----------------|-----|--------|
| **Swap file** | **4 GB** | Move `/swapfile` to e.g. `/home/swapfile` and point fstab there | Low |
| **Systemd journal** | **~1.3 GB** | Bind mount: store journal on `/home` and bind to `/var/log/journal` | Medium |
| **Snap packages** | **~4.1 GB** | Change snap layout (e.g. `SNAP_REAL_HOME`) or remove unused snaps | Medium / High |
| **Old Docker backups** | Tiny | Remove `/var/lib/docker_backup_*` (Docker already on `/home/docker-data`) | Low |
| **/var/log (old files)** | Part of 1.4G | Aggressive logrotate + truncate old logs | Low |

**Recommended order:** (1) Move swap to `/home`. (2) Cap or move journal. (3) Remove old docker_backup dirs. (4) Optionally trim snaps or move journal to `/home` via bind mount.

---

## [2026-03-08] USB HDD SMART health check (health.d module)

**Date:** 2026-03-08  
**Action:** Added SMART-based health check for the 3 USB HDDs (docking stations) so the homelab can warn before a disk is likely to fail.  
**Result:** New module `scripts/health.d/40-disk-smart.sh` runs as part of the existing health check. It detects disks from mount points `/mnt/disk1`, `/mnt/disk2`, `/mnt/disk_old`, runs `smartctl` (trying `-d sat` for USB bridges if needed), and alerts on SMART overall FAILED or on pre-failure attributes (Reallocated_Sector_Ct, Current_Pending_Sector, Offline_Uncorrectable).  
**Requirement:** Install smartmontools: `sudo apt install smartmontools`. If a USB enclosure does not pass SMART, the module logs and skips that drive.  
**Optional:** To monitor different mounts, edit the `USB_DISK_MOUNTS` array in `40-disk-smart.sh`.  
**Notification schedule:** The "💾 USB HDDs health" summary (OK + space per disk) is sent to Mattermost **only on Sunday** (when the daily run falls on Sunday 11:00). Failure/warning alerts are sent immediately on any run.  
**Standalone daily run:** As of 2026-03-08 the HDD check runs separately from the main health check: use `scripts/hdd-health-check.sh` with systemd timer `hdd-health-check.timer` (daily 11:00). See README “HDD health check (standalone, daily)” for deploy steps.

---

## [2026-03-03] FreshRSS: Unavailable on :8099 and URL – container not started + restarts required

**Date:** 2026-03-03  
**Symptoms:** http://localhost:8099 and https://rss.gmojsoski.com were unavailable.  
**Causes:** (1) FreshRSS container had never been started. (2) After adding a new service, Caddy and cloudflared must be restarted or the public URL stays 404.  
**Fix:**  
1. Start container: `cd docker/freshrss && docker compose up -d`.  
2. **Apply config and restart (required for any new service):**  
   - `cp cloudflare/config.yml ~/.cloudflared/config.yml`  
   - `cd docker/caddy && docker compose restart caddy`  
   - `cd docker/cloudflared && docker compose restart`  
3. Run `./scripts/verify-services.sh`.  
**Result:** Local :8099 and https://rss.gmojsoski.com both work (302 installer).  
**Remember:** New Caddy/tunnel routes only take effect after copying the tunnel config and restarting Caddy then cloudflared. See SERVICE_ADDITION_CHECKLIST.md “Restart Sequence”.

---

## [2026-03-03] Bookmarks: "URL is required" – rebuilt to accept form + JSON

**Date:** 2026-03-03  
**Symptoms:** POST to bookmarks.gmojsoski.com returned "URL is required" even when sending a URL.  
**Cause:** Old app only read `request.json` and expected key `url`; form submissions or different keys (e.g. `link`) were ignored.  
**Fix:** Rebuilt app in `Pi-version-control/apps/bookmarks/`: accepts both JSON and form data, accepts `url` / `link` / `bookmark_url`, validates URL (http/https), uses env for webhook and token (`.env` + systemd `EnvironmentFile`), added simple HTML form at `/`.  
**Deploy:** Copy `apps/bookmarks/*` to `/mnt/ssd/apps/bookmarks/`, ensure `.env` has `MATTERMOST_WEBHOOK_URL` and `BOOKMARKS_SECRET_TOKEN`, then `sudo systemctl restart bookmarks.service`.

---

## [2026-03-03] Immich: Photo backup service added

**Date:** 2026-03-03  
**Action:** Added Immich for self-hosted photo/video backup (Google Photos alternative).  
**Result:** Service at https://immich.gmojsoski.com, local http://localhost:2283 (port 2283).

### Configuration
- **docker/immich/**: docker-compose (server, ML, Redis, PostgreSQL), .env with `UPLOAD_LOCATION=/mnt/storage/immich-library` (3TB mergerfs). `IMMICH_IGNORE_MOUNT_CHECK_ERRORS=true` used so server starts on empty library; optional: run `sudo docker/immich/create-library-dirs.sh` to create .immich markers, then remove the flag.
- **Caddy:** docker/caddy/config.d/20-media.caddy — `immich.gmojsoski.com` → `http://172.17.0.1:2283` (no gzip).
- **Tunnel:** immich.gmojsoski.com in cloudflare/config.yml and ~/.cloudflared/config.yml → `http://localhost:8080`.
- **2FA:** No native TOTP; use Google OAuth (Administration → Settings) and 2FA on Google account, or Authentik.
- **Access control:** OAuth Auto Register disabled (only pre-created users can sign in); password login disabled in Settings so login is OAuth-only and not guessable.

### If Immich crashes on start (encoded-video/.immich ENOENT)
- Empty UPLOAD_LOCATION lacks subdirs; either set `IMMICH_IGNORE_MOUNT_CHECK_ERRORS=true` in .env or run `sudo docker/immich/create-library-dirs.sh /mnt/storage/immich-library`.

---

## [2026-02-17] Clawdbot: Switched from Google Gemini to local Ollama

**Date:** 2026-02-17  
**Action:** Removed Gemini API key and configured Clawdbot to use local Ollama (DeepSeek R1 1.5B).  
**Result:** Clawdbot now uses `ollama/deepseek-r1:1.5b` on the host; no cloud API key required.

### Changes
- **docker/clawdbot/docker-compose.yml**: Removed `GEMINI_API_KEY` and `GOOGLE_API_KEY`. Added `OLLAMA_API_KEY` and `extra_hosts: host.docker.internal:host-gateway` so the gateway container can reach Ollama on the host.
- **docker-data/clawdbot/config/clawdbot.json**: Replaced `google` provider with `ollama` provider (`baseUrl: http://host.docker.internal:11434/v1`), primary model `ollama/deepseek-r1:1.5b`. Backup saved as `clawdbot.json.bak`.

### Prerequisites
- Ollama must be running on the host (e.g. `ollama serve`) and model `deepseek-r1:1.5b` pulled.

### Rollback
- To revert: restore `clawdbot.json` from `clawdbot.json.bak`, re-add Gemini env vars to docker-compose, and restart the gateway.

### [2026-02-17] Reverted to Google Gemini (local Ollama too slow / stuck)
- Local Ollama (1.5B/3B) was too slow on CPU; Clawd stayed on "molt is typing..." and did not respond in time.
- **Action:** Switched Clawdbot back to Google Gemini: restored `google` provider and `google/gemini-2.5-flash` in `clawdbot.json`, re-added `GEMINI_API_KEY` / `GOOGLE_API_KEY` in docker-compose.
- **User:** Set `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) in `docker/clawdbot/.env` and restart the gateway.

---

## [2026-01-29] CPU Upgrade - Intel Pentium G4560T → Intel Core i5-7500T

**Date:** 2026-01-29  
**Action:** Replaced CPU from Intel Pentium G4560T (2 cores, 4 threads) to Intel Core i5-7500T (4 cores, 4 threads)  
**Result:** Successful upgrade with no software changes required

### ✅ Hardware Change
- **Previous CPU**: Intel Pentium G4560T @ 2.90GHz (2 Cores, 4 Threads)
- **New CPU**: Intel Core i5-7500T @ 2.70GHz (4 Cores, 4 Threads)
- **Machine**: Lenovo ThinkCentre M710q
- **BIOS**: M1AKT18A (05/03/2017)

### 🔍 Verification
- CPU detected correctly: `Intel(R) Core(TM) i5-7500T CPU @ 2.70GHz` ✅
- All 4 cores recognized by system ✅
- Docker services running (30 containers active) ✅
- No software configuration changes required ✅

### 📝 Notes
- Both CPUs are 7th generation (Kaby Lake) - same architecture (x86_64)
- No driver or kernel changes needed
- All services continue to function normally
- Performance improvement: 2 cores → 4 cores (better parallel processing)
- Lower base clock (2.70GHz vs 2.90GHz) but more cores for better multi-threaded performance

### ✅ Status
CPU upgrade completed successfully. System operational with improved multi-core performance.

---

## [2026-01-28] Portfolio Layout Issues - Cache Busting Mismatch

**Date:** 2026-01-28  
**Symptoms:**
- Portfolio site (`gmojsoski.com`) showing broken layout on desktop
- Duplicated social icons visible in Contact section
- "Show more" buttons not working on Personal Projects section
- Cache appearing to serve old assets despite latest code being deployed

**Root Cause Identified:**
1. **Local Uncommitted Changes**: Cache-busting query strings (`?v=20260128`) were added to asset links in `index.html` to force Cloudflare cache refresh
2. **Sync Mismatch**: These changes were never committed to git, so `make portfolio-update` pulled clean code from GitHub without the cache busters
3. **Version Mismatch**: Live site served assets without cache busters → Cloudflare served stale cached CSS/JS from December while HTML was from January
4. **Confusion**: Issue appeared after Caddy configuration split, making it seem related to that change when it was actually a cache/sync problem

**Solution Applied:**
1. **Restored Clean State**: Ran `git restore index.html` in portfolio repository to match GitHub `main` branch exactly
2. **Re-synced**: Ran `make portfolio-update` to ensure complete sync from repository to live site
3. **Removed Temporary Fix**: Removed the `no-cache` headers that were added to Caddy as a workaround
4. **Verified Paths**: Confirmed `/home/docker-projects/caddy` and `/mnt/ssd/docker-projects/caddy` are the same directory (symlinked, inode: 9942018)

**Verification:**
- Portfolio repository shows clean working tree ✅
- `make portfolio-update` reports "Already up to date" ✅
- Live site matches GitHub `main` branch exactly ✅

**Key Lessons Learned:**
1. **Don't Mix Fixes**: Cache-busting changes should be committed to git OR not used at all; uncommitted changes create sync mismatches
2. **Cloudflare Caching**: Cloudflare edge caching can persist old assets even when server is updated
3. **Hard Refresh Required**: Users need to hard refresh (Ctrl+Shift+R) or use incognito mode after cache issues
4. **Sync Verification**: Always verify that local changes match what's deployed when troubleshooting "broken" sites

**Files Involved:**
- `/home/goce/Desktop/Cursor projects/portfolio/portfolio/index.html` - Repository file
- `/home/docker-projects/caddy/site/index.html` - Live site (symlinked to `/mnt/ssd/docker-projects/caddy/site/index.html`)
- `scripts/update-portfolio.sh` - Sync script

**Status**: ✅ Resolved - Site restored to clean state from `main` branch

---

## [2026-01-28] Configured Clawdbot Web Search (Brave Search)

**Date:** 2026-01-28
**Action:** Used `clawdbot configure --section web` to enable Brave Search and web fetch.
**Result:** Clawdbot can now perform live web searches using the Brave Search API.

### ✅ Changes Made
1. **Enabled Web Search**: Switched `tools.web.search.enabled` to `true` in `clawdbot.json`.
2. **Set API Key**: Provided the Brave Search API key to the configuration tool.
3. **Enabled Web Fetch**: Switched `tools.web.fetch.enabled` to `true` to allow reading web content.
4. **Service Restarted**: Restarted the `clawdbot-gateway` container to apply changes.

### 🧪 Verification
- Config file `clawdbot.json` verified to contain the `tools` section with correct settings.
- Service restarted successfully.

---

## [2026-01-28] Caddy Configuration Outage after Splitting

**Date:** 2026-01-28
**Action:** Splitting monolithic Caddyfile into service-specific configurations in `config.d/`
**Result:** Service went down during initial attempt; successfully restored with modular structure.

### 🔴 Symptoms
- Caddy service failed to start after splitting the Caddyfile.
- Port 8080 (reverse proxy) became unresponsive.
- All services behind the proxy returned connection errors.

### 🔍 Root Cause Identified
1. **Missing Config Mount**: The `config.d` directory was not properly mounted or referenced in the production Caddy instance.
2. **Explicit Import Errors**: Using explicit individual imports made the configuration fragile (a missing file would crash the entire proxy).

### ✅ Solution Applied
1. **Wildcard Import**: Updated `Caddyfile` to use `import /etc/caddy/config.d/*.caddy`.
2. **Consistent Extensions**: Renamed all split configs to `.caddy`.
3. **Volume Mount**: Ensured `config.d` is correctly mounted to `/etc/caddy/config.d` in `docker-compose.yml`.
4. **Validation**: Used `caddy validate` via Docker to verify syntax before deployment.

---

## [2026-01-28] Modular Health Check System Migration

**Date:** 2026-01-28
**Action:** Migrated monolithic `enhanced-health-check.sh` to a modular engine with service-specific plugins.
**Result:** Reduced CPU churn and improved maintainability.

### 🔍 Improvements
1. **Modular Engine**: `health-check-engine.sh` now sources small check scripts from `health.d/`.
2. **Interval Optimization**: Increased health check interval from **3 minutes** to **15 minutes** as requested by the user.
3. **Robustness**: A failure in one check module no longer risks the entire script's execution.

### ✅ Verification
- Manual execution confirmed the engine picks up and runs all modules in `health.d/`.
- Systemd timer successfully updated to 15-minute intervals.

---

## [2026-01-16] Backup Cron Job Failing - Permission Denied on Log File

**Date:** 2026-01-10
**Action:** Attempted to enable plugin uploads in Mattermost by modifying config.json directly
**Result:** Mattermost returned 502 Bad Gateway, service unavailable

### 🔴 Symptoms
- Mattermost returning **502 Bad Gateway** immediately after configuration change
- Service completely unavailable
- Container may have been running but not responding

### 🔍 Root Cause Identified
1. **Direct config.json Modification**: Attempted to modify `config.json` file directly inside the Docker container to enable plugin uploads (`PluginSettings.EnableUploads: true`)
2. **Config Corruption**: The direct modification likely corrupted the JSON structure or introduced syntax errors
3. **Mattermost Startup Failure**: Mattermost couldn't parse the corrupted config.json and failed to start properly
4. **Unnecessary Complexity**: The docker-compose.yml already had `MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"` environment variable set, which should have been sufficient

### ✅ Solution Applied
1. **Stop Mattermost**: `docker compose stop mattermost`
2. **Remove Corrupted Config**: Used temporary container to remove corrupted `config.json` from Docker volume:
   ```bash
   docker run --rm -v mattermost_mattermost-config:/config busybox sh -c "rm -f /config/config.json"
   ```
3. **Restart Mattermost**: `docker compose up -d mattermost`
4. **Config Regeneration**: Mattermost automatically regenerated `config.json` from environment variables on startup

### 📝 Key Lessons Learned
1. **Use Environment Variables First**: Mattermost's docker-compose.yml already had `MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"` which should have been sufficient. Environment variables are the preferred method for Mattermost configuration.
2. **Avoid Direct Config.json Modifications**: Modifying config.json directly can cause corruption and service failures. Mattermost manages config.json internally from environment variables.
3. **Environment Variables > Direct File Edits**: When both methods exist, prefer environment variables:
   - Environment variables in docker-compose.yml are more maintainable
   - Mattermost automatically merges environment variables into config.json
   - Direct file edits bypass Mattermost's configuration management system
4. **Recovery Method**: If config.json is corrupted, simply delete it and let Mattermost regenerate from environment variables on restart.

### 🔧 Correct Approach for Future Plugin Upload Enable
If you need to enable plugin uploads in Mattermost, use **ONLY** the environment variable (already set in docker-compose.yml):
```yaml
environment:
  MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"
```

**DO NOT** modify config.json directly. Mattermost will read the environment variable and configure itself accordingly on startup.

### ✅ Verification
- Mattermost accessible at `https://mattermost.gmojsoski.com` ✅
- Service responding with HTTP 200 ✅
- Plugin uploads enabled via environment variable ✅
- Config.json regenerated successfully ✅

### 📍 Files Involved
- `docker/mattermost/docker-compose.yml` - Contains `MM_PLUGINSETTINGS_ENABLEUPLOADS: "true"` (correct method)
- Docker volume: `mattermost_mattermost-config:/mattermost/config` - Contains config.json (managed by Mattermost)

**Status**: ✅ Resolved - Mattermost restored and plugin uploads enabled via environment variable

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

---

## [2026-01-16] Backup Cron Job Failing - Permission Denied on Log File

**Date:** 2026-01-16
**Action:** Backup verification script detected backups haven't run in 17 days (last backup: Dec 30, 2025)
**Result:** Backup cron job configured but not executing due to log file permission error

### 🔴 Symptoms
- Backup verification script reports backups haven't run in 17 days
- Last backup created: Dec 30, 2025 at 21:07
- Cron service is running and active
- Backup cron job configured in `/etc/crontab`
- No errors in cron logs about backup execution
- Manual backup execution works correctly

### 🔍 Root Cause Identified
1. **Log File Permission Issue**: Cron job configured to write logs to `/var/log/backup-all-critical.log`
2. **User Permission Denied**: User `goce` cannot create/write to `/var/log/` directory (requires root/sudo)
3. **Cron Job Failing Silently**: When cron tries to redirect output (`>> /var/log/backup-all-critical.log 2>&1`), it fails due to permission denied, causing the entire cron job to fail
4. **No Log File Exists**: `/var/log/backup-all-critical.log` doesn't exist, and user `goce` cannot create it

### ✅ Solution Applied
1. **Created Fix Script**: `scripts/fix-backup-cron-log.sh` to update crontab log path
2. **Changed Log Location**: Updated crontab to use user-writable log directory:
   - **Old**: `/var/log/backup-all-critical.log` (requires root)
   - **New**: `/home/goce/Desktop/Cursor projects/Pi-version-control/logs/backup-all-critical.log` (user-writable)
3. **Fix Script Actions**:
   - Backs up original `/etc/crontab` before changes
   - Creates log directory if it doesn't exist
   - Updates crontab entry using `sed` to replace log path
   - Verifies the change was applied correctly

### 🔧 Fix Script Usage
```bash
# Run the fix script (requires sudo)
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-backup-cron-log.sh"

# After fix, verify crontab entry
grep "backup-all-critical" /etc/crontab

# Monitor next backup run (at 2:00 AM)
tail -f "/home/goce/Desktop/Cursor projects/Pi-version-control/logs/backup-all-critical.log"
```

### 📝 Key Lessons Learned
1. **User-Writable Log Directories**: Always use user-writable log directories for user cron jobs, not `/var/log/`
2. **Cron Permission Failures**: Cron jobs fail silently when output redirection fails (permission denied)
3. **Log Directory Best Practice**: Use project-specific log directories (e.g., `$PROJECT_DIR/logs/`) instead of system log directories
4. **Verification Script Value**: Backup verification script successfully detected the issue (missing/old backups)

### ✅ Verification
After fix is applied:
- Backup cron job will execute at 2:00 AM daily ✅
- Logs will be written to user-writable location ✅
- Backup verification script will detect new backups ✅

### 📝 Related Files
- **Cron Job**: `/etc/crontab` (line with `backup-all-critical.sh`)
- **Fix Script**: `scripts/fix-backup-cron-log.sh`
- **Log Location**: `logs/backup-all-critical.log` (after fix)
- **Backup Script**: `scripts/backup-all-critical.sh`

## [2026-02-22] Hardware Upgrade & Docker Data Migration

**Date:** 2026-02-22  
**Action:** Attached a new 1TB HDD, formatted it to ext4, mounted it to `/mnt/storage`, and migrated the Docker root directory from root (`/var/lib/docker`) to `/home/docker-data`.  
**Result:** Reclaimed space on the root partition and enabled large local storage for extensive data like Kiwix archives.

### ✅ Changes Made
1. **1TB HDD Setup:** Formatted `/dev/sda1` to `ext4` and mounted it at `/mnt/storage` using its UUID in `/etc/fstab` to ensure survival across reboots or moving between dock and SATA.
2. **Docker Migration:**
   - Stopped Docker service and socket.
   - Synchronized all data using `rsync -aP /var/lib/docker/ /home/docker-data/`.
   - Reconfigured Docker daemon via `/etc/docker/daemon.json` setting `"data-root": "/home/docker-data"`.
   - Renamed old directory (`/var/lib/docker.old`) to preserve as a temporary backup.
3. **Kiwix Setup:**
   - Created `/mnt/storage/kiwix-data/` to hold `.zim` archives natively on the new drive.
   - Initialized a resilient background `wget -c` download for the 55GB Wikipedia offline English archive (no-pics).
   - Spun up the Kiwix Docker container serving the directory on port **8089** (since 8088 was already occupied by Portainer).

### 🧪 Verification
- `df -h` confirms `/mnt/storage` has ~916GB available space.
- `docker info` lists `Docker Root Dir: /home/docker-data`.
- Kiwix interface accessible via `http://<device-ip>:8089`.

---

## [2026-02-26] Storage Expansion - 3 New USB HDDs Added (mergerfs Pool)

**Date:** 2026-02-26
**Action:** Connected three external HDDs (2TB, 1TB, 500GB) via USB docking stations, wiped all three, formatted them to `ext4`, and configured a `mergerfs` pool combining the 2TB and 1TB drives.
**Result:** 3TB `mergerfs` storage pool available at `/mnt/storage`. Old 500GB drive mounted separately at `/mnt/disk_old`.

### ✅ Drives Configured

| Drive | Physical Size | Label | Mount Point | Notes |
|-------|--------------|-------|-------------|-------|
| `/dev/sdb` | 1TB | `disk1` | `/mnt/disk1` | Part of mergerfs pool |
| `/dev/sdd` | 2TB | `disk_pool1` | `/mnt/disk2` | Part of mergerfs pool |
| `/dev/sdc` | 500GB (2013) | `disk2` | `/mnt/disk_old` | Isolated - old/possibly unreliable |
| `mergerfs` | ~3TB combined | — | `/mnt/storage` | **Main external storage** |

### 🔧 Steps Performed

1. **Unmounted** auto-mounted NTFS partitions from `/media/goce/`
2. **Wiped** all three drives with `wipefs -a`
3. **Partitioned** all three with GPT + single ext4 partition via `parted`
4. **Formatted** to `ext4` (used `-F` flag to force past NTFS signature detection)
5. **Removed stale old fstab entry** for `UUID=1c5174bc` (previous 1TB `/mnt/storage` drive, no longer present)
6. **Created mount points**: `/mnt/disk1`, `/mnt/disk2`, `/mnt/disk_old`, `/mnt/storage`
7. **Mounted** all three drives individually
8. **Created mergerfs pool**: `/mnt/disk1:/mnt/disk2` → `/mnt/storage` (policy: `mfs` - most free space)
9. **Updated `/etc/fstab`** with UUID-based entries for all 3 drives and the mergerfs pool

### 📍 Fstab Entries Added
```
UUID=fdb8956e-eb47-46c6-a8ff-d9a0e223782f  /mnt/disk1     ext4         defaults,nofail  0  2
UUID=139b09c3-efda-4d88-b9aa-8b20aadd1873  /mnt/disk2     ext4         defaults,nofail  0  2
UUID=a93c91ca-b06b-4a1e-ad4d-353ddf221319  /mnt/disk_old  ext4         defaults,nofail  0  2
/mnt/disk1:/mnt/disk2  /mnt/storage  fuse.mergerfs  defaults,allow_other,use_ino,category.create=mfs,minfreespace=100M,x-systemd.requires=/mnt/disk1,x-systemd.requires=/mnt/disk2  0  0
```

### 🧪 Verification
```
/dev/sdb1  916G  used: 2.1M  avail: 870G  → /mnt/disk1  ✅
/dev/sdd1  1.8T  used: 2.1M  avail: 1.7T  → /mnt/disk2  ✅
/dev/sdc1  458G  used: 2.1M  avail: 435G  → /mnt/disk_old  ✅
mergerfs   2.7T  used: 4.1M  avail: 2.6T  → /mnt/storage  ✅
```
- Write/read test to `/mnt/storage` and `/mnt/disk_old` passed ✅
- `systemctl daemon-reload` run after fstab update ✅

### ⚠️ Notes
- The 500GB drive is from 2013; treat as non-critical storage only.
- Consider running `sudo badblocks -sv /dev/sdc` on the old drive to check health before trusting it.
- **Point Docker volumes, Kiwix data, and media at `/mnt/storage`** for primary use.
