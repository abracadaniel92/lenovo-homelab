# Changelog - January 11, 2026

## Summary

Major performance optimizations and cleanup to reduce CPU usage and improve system stability. Added Mattermost push notifications and webhook bot username configuration.

## Changes Made

### 🗑️ Removed Services

1. **Zulip Removed** - Service was consuming 220% CPU due to constant crash loops
   - All containers stopped and removed
   - All volumes deleted
   - Configuration files cleaned up
   - References removed from documentation

### ⚡ Performance Optimizations

1. **Health Check Interval Reduced**
   - Changed from every 30 seconds to every 3 minutes (6x reduction)
   - Significantly reduces CPU overhead
   - Updated in: `scripts/permanent-auto-recovery.sh`
   - Timer configuration: `OnUnitActiveSec=3min`

2. **Portfolio Update Made Manual**
   - Disabled automatic portfolio update timer (was running every 5 minutes)
   - New manual command: `lab-make portfolio-update`
   - Reduces CPU usage

### 🔧 New Commands Added

1. **Health Check Commands**
   - `lab-make health` - Run health check manually
   - `lab-make health-verify` - Verify timer configuration
   - `lab-make health-fix` - Fix/update timer if needed

2. **Portfolio Update**
   - `lab-make portfolio-update` - Manually update portfolio from GitHub

### 📝 Documentation Updates

1. **LAB_COMMANDS.md** - Updated with all new commands
2. **HEALTH_CHECK_STATUS.md** - New documentation for health check configuration
3. **INSTALL_PORTFOLIO_UPDATE.md** - Instructions for portfolio update setup
4. **README.md** - Updated monitoring frequency (3 minutes)
5. **MONITORING_AND_RECOVERY.md** - Updated health check interval

### 🔒 Security Improvements

1. **Sensitive Data Sanitization**
   - Removed hardcoded password from `systemd/planning-poker.service`
   - Removed hardcoded password from `scripts/archive/fix-bookmarks-poker-complete.sh`
   - Both now use placeholder: `CHANGE_ME_IN_PRODUCTION`

2. **Webhook URLs**
   - Mattermost webhook URLs remain as defaults but can be overridden via environment variables
   - Documented in scripts that they can be set via `.env` file

### 💬 Mattermost Improvements

1. **Mobile Push Notifications Enabled**
   - Enabled push notifications via TPNS (Test Push Notification Service)
   - Configuration added to `docker/mattermost/docker-compose.yml`:
     - `MM_EMAILSETTINGS_SENDPUSHNOTIFICATIONS: "true"`
     - `MM_EMAILSETTINGS_PUSHNOTIFICATIONSERVER: "https://push-test.mattermost.com"`
   - Requires configuration in System Console → Environment → Push Notification Server
   - TPNS is free for non-commercial self-hosted installations

2. **Webhook Bot Usernames**
   - Updated all Mattermost webhook scripts to use custom bot usernames:
     - `enhanced-health-check.sh` → "System Bot"
     - `slack-pi-monitoring.sh` → "System Bot"
     - `slack-goatcounter-weekly.sh` → "Analytics Bot"
   - Created test script: `scripts/test-mattermost-webhook.sh`
   - Requires System Console → Integrations → Enable "Override usernames" setting
   - Updated `docker/mattermost/README.md` with configuration instructions

3. **Health Check Removed**
   - Removed Docker healthcheck from Mattermost (curl not available in container)
   - Mattermost verified to be working via API ping from host

### 📁 Files Modified

#### Configuration Files
- `docker/caddy/Caddyfile` - Removed Zulip reverse proxy block
- `docker/mattermost/docker-compose.yml` - Added push notification settings, removed healthcheck
- `scripts/verify-services.sh` - Removed zulip.gmojsoski.com
- `scripts/enhanced-health-check.sh` - Added "System Bot" username to webhook payload
- `scripts/slack-pi-monitoring.sh` - Added "System Bot" username to webhook payload
- `scripts/slack-goatcounter-weekly.sh` - Added "Analytics Bot" username to webhook payload
- `Makefile` - Added health-verify, health-fix, portfolio-update commands
- `Makefile` - Updated to use CURDIR for location independence
- `systemd/portfolio-update.timer` - Marked as disabled
- `scripts/permanent-auto-recovery.sh` - Updated timer interval to 3min

#### Documentation
- `README.md` - Removed Zulip references, updated monitoring frequency
- `docker/mattermost/README.md` - Added push notification and webhook bot username configuration instructions
- `restart services/LAB_COMMANDS.md` - Added all new commands
- `usefull files/MONITORING_AND_RECOVERY.md` - Updated intervals
- `docs/reference/infrastructure-summary.md` - Removed Zulip
- `docs/how-to-guides/pi-hole-setup.md` - Removed Zulip references

#### New Files
- `scripts/verify-health-check.sh` - Verification script
- `scripts/fix-health-check-timer.sh` - Timer fix script
- `scripts/portfolio-update-wrapper.sh` - Portfolio update wrapper
- `scripts/test-mattermost-webhook.sh` - Test script for Mattermost webhook bot usernames
- `HEALTH_CHECK_STATUS.md` - Health check documentation
- `INSTALL_PORTFOLIO_UPDATE.md` - Portfolio update installation guide

#### Removed Files
- `docker/zulip/` - Entire directory removed

### 🔍 Verification Commands

```bash
# Verify health check configuration
lab-make health-verify

# Check current timer interval
systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value

# Check system load
uptime
docker stats --no-stream
```

## Performance Impact

**Before:**
- Zulip using 220% CPU (constant crash loops)
- Health check every 30 seconds
- Portfolio update every 5 minutes
- Load average: ~21 on 4-core system

**After:**
- Zulip removed
- Health check every 3 minutes (6x reduction)
- Portfolio update manual only
- Expected load average: Significantly reduced

## Migration Notes

### If Timer Still Shows 30 Seconds

Run the fix command:
```bash
lab-make health-fix
```

Or manually:
```bash
sudo systemctl daemon-reload
sudo systemctl restart enhanced-health-check.timer
```

### Portfolio Updates

Previously automatic, now manual:
```bash
lab-make portfolio-update
```

## Breaking Changes

- **Portfolio updates** are no longer automatic - must be run manually
- **Zulip service** completely removed - any references need to be cleaned up

## Notes

- All webhook URLs in scripts are defaults and can be overridden via environment variables
- Passwords in service files have been sanitized to placeholders
- Sensitive data should be managed via `.env` files (which are gitignored)

