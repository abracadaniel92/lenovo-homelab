# Changelog

## December 2025

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

