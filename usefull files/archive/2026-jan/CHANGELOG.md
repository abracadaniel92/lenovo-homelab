# Changelog

## December 2025

### December 29, 2025 - Service Fixes and Optimizations

#### Planning Poker Mobile Browser Fix (December 29, 2025)
- **Issue**: Mobile browsers showing blank screen and downloading HTML as text file instead of displaying
- **Root Cause**: Express.js not setting explicit Content-Type headers for static files
- **Fix**: Updated `server.js` to explicitly set Content-Type headers:
  - HTML: `text/html; charset=UTF-8`
  - CSS: `text/css; charset=UTF-8`
  - JS: `application/javascript; charset=UTF-8`
- **File Modified**: `planning_poker/server.js` (in planning_poker repository)
- **Status**: ✅ Fixed
- **Documentation**: `POKER_MOBILE_FIX.md`

#### Planning Poker Bar Chart Mobile Alignment (December 29, 2025)
- **Issue**: Vote distribution bar chart not aligned properly on mobile devices
- **Root Cause**: Flexbox alignment issues on small screens, items not aligning to bottom
- **Fix**: 
  - Added `justify-content: flex-end` to items for bottom alignment
  - Added horizontal scroll for many votes on small screens
  - Improved mobile-specific sizing and spacing
  - Fixed label positioning and text wrapping
- **File Modified**: `planning_poker/public/style.css` (in planning_poker repository)
- **Status**: ✅ Fixed

#### TravelSync Document Processing Performance (December 29, 2025)
- **Issue**: Document processing taking 48+ seconds, causing timeouts and crashes
- **Root Causes**:
  1. Slow scikit-image `denoise_nl_means` operation (30+ seconds)
  2. OCR running on all images (2-5 seconds)
  3. Image enhancement causing delays
  4. No timeout handling for Gemini API calls
- **Fixes Applied**:
  - Removed slow scikit-image denoising, using fast OpenCV denoising instead
  - Disabled OCR by default (can be enabled for best processing)
  - Disabled image enhancement by default (can be enabled for best processing)
  - Added 30-second timeout to Gemini API calls with proper async handling
  - Run Gemini calls in thread pool to prevent blocking
- **Performance Improvement**: Reduced from 48+ seconds to < 10 seconds (80%+ faster)
- **Files Modified**: `travelsync/backend/services/document_processor.py` (in travelsync repository)
- **Status**: ✅ Fixed
- **Documentation**: `PERFORMANCE_OPTIMIZATIONS.md` (in travelsync repository)

#### TravelSync "Body is Locked" Error Fix (December 29, 2025)
- **Issue**: Upload endpoint crashing with "body is locked" or "body is disturbed" error
- **Root Cause**: Accessing `file.content_type` after reading file with `await file.read()`
- **Fix**: Reordered operations to get content_type BEFORE reading file:
  1. Get content_type first
  2. Validate file type
  3. Read file contents (only once)
- **File Modified**: `travelsync/backend/main.py` (in travelsync repository)
- **Status**: ✅ Fixed
- **Documentation**: `BODY_LOCKED_FIX.md` (in travelsync repository)

#### TravelSync Format String Error Fix (December 29, 2025)
- **Issue**: "Invalid format specifier" error when processing documents
- **Root Cause**: Prompts used f-strings with JSON format examples containing `{` and `}` that Python interpreted as format placeholders
- **Fix**: Changed prompts from f-strings to regular strings, using string concatenation for dynamic parts
- **Files Modified**: `travelsync/backend/services/document_processor.py` (in travelsync repository)
- **Status**: ✅ Fixed

#### TravelSync Best Processing Mode (December 29, 2025)
- **Enhancement**: Re-enabled OCR and image enhancement for best processing accuracy
- **Configuration**: 
  - OCR runs on images > 224x224 pixels
  - Image enhancement enabled for better Gemini processing
  - Format string issues resolved to allow proper prompt formatting
- **Files Modified**: `travelsync/backend/services/document_processor.py` (in travelsync repository)
- **Status**: ✅ Complete

### Service Fixes

#### Bookmarks Service (December 28, 2025)
- **Issue**: Service was returning 404 for health checks, causing Uptime Kuma to report it as down
- **Root Cause**: Flask app only had `/bookmark` POST route, no GET route for health checks
- **Fix**: Added health check route (`/`) that returns `{"status": "ok", "service": "bookmarks"}`
- **File Modified**: `/mnt/ssd/apps/bookmarks/secure_slack_bookmarks.py`
- **Status**: ✅ Fixed

#### Planning Poker Service (December 28, 2025)
- **Issue**: Service was not running, causing 502 Bad Gateway errors
- **Root Cause**: No systemd service existed, and Node.js path was incorrect (using nvm)
- **Fix**: 
  - Created systemd service file: `systemd/planning-poker.service`
  - Configured to use nvm Node.js path: `/home/goce/.nvm/versions/node/v20.19.6/bin/node`
  - Added to health check monitoring
  - Enabled auto-start on boot
- **Status**: ✅ Fixed

#### Cloudflare Tunnel (December 28, 2025)
- **Issue**: Tunnel was connected but returning 502 Bad Gateway errors
- **Root Cause**: DNS configuration in Cloudflare dashboard not pointing to tunnel
- **Fix**: Updated DNS records to point to tunnel CNAME
- **Status**: ✅ Fixed

#### Poker Frontend (December 28, 2025)
- **Issue**: Poker service was accessible but CSS/JS files weren't loading (404 errors)
- **Root Cause**: Caddy reverse proxy wasn't forwarding Host header to Express server
- **Fix**: Added `Host` and `X-Forwarded-Host` header forwarding to poker route in Caddyfile
- **File Modified**: `docker/caddy/Caddyfile`
- **Status**: ✅ Fixed

#### Nextcloud Routing (December 28, 2025)
- **Issue**: Nextcloud returning 502 Bad Gateway via Caddy
- **Root Cause**: Caddy and Nextcloud containers on different Docker networks, couldn't resolve `nextcloud-app` hostname
- **Fix**: Changed Caddy route from `http://nextcloud-app:80` to `http://172.17.0.1:8081` (host IP and port)
- **File Modified**: `docker/caddy/Caddyfile`
- **Status**: ✅ Fixed

#### Travelsync Route (December 28, 2025)
- **Issue**: Travelsync domain not configured
- **Fix**: Added `travelsync.gmojsoski.com` route to Caddyfile and Cloudflare config
- **File Modified**: `docker/caddy/Caddyfile`, `cloudflare/config.yml`
- **Status**: ✅ Fixed

### Monitoring Improvements

#### Uptime Kuma Setup (December 28, 2025)
- Added monitors for all services:
  - Caddy (Local)
  - Cloudflared Tunnel (Public)
  - GoatCounter
  - Gokapi
  - Bookmarks
  - Planning Poker
  - Nextcloud
  - Documents-to-Calendar
- All monitors configured with Slack notifications
- Status: ✅ Complete

#### Health Check System Updates (December 28, 2025)
- **Interval**: Reduced from 5 minutes to 2 minutes for faster detection
- **Services Added**: planning-poker.service
- **Scripts Updated**:
  - `health-check-and-restart.sh` - Added planning-poker monitoring
  - `ensure-services-running.sh` - Added planning-poker startup
  - `optimize-system.sh` - Added planning-poker to auto-start
- **Status**: ✅ Complete

### Documentation Updates

#### README.md (December 28, 2025)
- Updated from "Raspberry Pi" to "Lenovo ThinkCentre"
- Changed architecture references from ARM64 to x86_64
- Updated download links (cloudflared, gokapi) from arm64 to amd64
- Added Bookmarks and Planning Poker to service list
- Updated service ports reference
- Updated domain routing table

#### STABILITY_FIXES.md (December 28, 2025)
- Added recent fixes section
- Updated health check interval documentation
- Added planning-poker to auto-start services list
- Added service ports for poker

#### New Files Created
- `SERVICES_STATUS.md` - Current status of all services
- `systemd/planning-poker.service` - Systemd service file for planning poker
- `UPTIME_KUMA_CADDY_SETUP.md` - Uptime Kuma setup guide
- `UPTIME_KUMA_SLACK_CLOUDFLARED.md` - Slack notifications guide
- `CLOUDFLARED_TUNNEL_FIX.md` - Cloudflare tunnel troubleshooting
- `BOOKMARKS_POKER_FIX.md` - Bookmarks and poker fix documentation
- `POKER_FRONTEND_FIX.md` - Poker frontend CSS/JS loading fix
- `POKER_GOKAPI_TRAVELSYNC_FIX.md` - Routing fixes for multiple services
- `CONFIGURATION_AUDIT.md` - Configuration verification results
- `QUICK_SSH_COMMANDS.md` - Quick reference for mobile SSH troubleshooting
- `EMERGENCY_RESTORE.md` - Emergency service restore procedures
- `WHAT_I_DID.md` - Explanation of service outage causes

### Scripts Created/Updated

#### New Scripts
- `fix-cloudflared-restart.sh` - Fixes cloudflared restart policy
- `update-health-check-interval.sh` - Updates health check interval
- `fix-cloudflared-tunnel.sh` - Comprehensive tunnel troubleshooting
- `setup-uptime-kuma-cloudflared.sh` - Uptime Kuma monitor setup
- `setup-uptime-kuma-monitors.sh` - Multiple monitor setup
- `setup-uptime-kuma-services.sh` - Service monitor setup
- `fix-bookmarks-poker.sh` - Diagnostics for bookmarks/poker
- `fix-bookmarks-poker-complete.sh` - Complete fix script
- `fix-poker-gokapi-travelsync.sh` - Fix routing for poker, gokapi, and travelsync
- `fix-docker-restart-policies.sh` - Updates Docker restart policies to 'always'
- `verify-configuration.sh` - Comprehensive configuration verification

#### Updated Scripts
- `health-check-and-restart.sh` - Added planning-poker monitoring
- `ensure-services-running.sh` - Added planning-poker startup
- `optimize-system.sh` - Added planning-poker to auto-start

## Migration Notes

### From Raspberry Pi (ARM64) to Lenovo ThinkCentre (x86_64)
- All binaries updated to x86_64 versions
- Node.js now uses nvm installation path
- Service configurations updated for new system
- Health check system enhanced

