# Health Check Configuration Status

## ✅ Configuration Summary

The health check system runs **every hour** (changed from 3 minutes).

### Files Updated:

1. **`scripts/permanent-auto-recovery.sh`** ✅
   - Timer interval: `OnUnitActiveSec=1h` (line 144)
   - Description: "Every Hour" (line 139)
   - AccuracySec: `30s`

2. **`Makefile`** ✅
   - Health command: `make health` or `lab-make health`
   - Verification command: `make health-verify` or `lab-make health-verify`
   - Uses `CURDIR` for location-independent paths

3. **`scripts/enhanced-health-check.sh`** ✅
   - Script exists and is complete (336 lines)
   - Monitors: Docker, Caddy, Cloudflare Tunnel, TravelSync, Planning Poker, Nextcloud, Jellyfin, Bookmarks, Gokapi

4. **`scripts/verify-health-check.sh`** ✅
   - New verification script created
   - Checks timer interval, service status, script location, log file

## 🔍 How to Verify Current Configuration

### Option 1: Use the Makefile Command
```bash
lab-make health-verify
```

### Option 2: Run Verification Script Directly
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
bash scripts/verify-health-check.sh
```

### Option 3: Manual Check
```bash
# Check timer interval
systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value

# Check timer status
systemctl status enhanced-health-check.timer

# Check next run time
systemctl list-timers enhanced-health-check.timer
```

## 🔧 If Timer Needs Updating

If the verification shows the timer is still at 30 seconds, update it:

### Method 1: Re-run Installation Script (Recommended)
```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
sudo bash scripts/permanent-auto-recovery.sh
```

### Method 2: Manual Update
```bash
# Update the timer file
sudo tee /etc/systemd/system/enhanced-health-check.timer > /dev/null << 'EOF'
[Unit]
Description=Run Enhanced Health Check Every Hour
Requires=enhanced-health-check.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=1h
AccuracySec=30s

[Install]
WantedBy=timers.target
EOF

# Reload systemd and restart timer
sudo systemctl daemon-reload
sudo systemctl restart enhanced-health-check.timer

# Verify it's correct
systemctl show enhanced-health-check.timer -p OnUnitActiveSec --value
```

## 📊 Expected Configuration

- **Timer Interval**: `1h` (or `3600s` or `3600000000` microseconds)
- **Boot Delay**: `1min` (waits 1 minute after boot)
- **Accuracy**: `30s` (timer can be delayed by up to 30 seconds for efficiency)
- **Service**: `/etc/systemd/system/enhanced-health-check.service`
- **Script**: `/usr/local/bin/enhanced-health-check.sh`
- **Log**: `/var/log/enhanced-health-check.log`

## 🚀 Quick Commands

```bash
# Run health check manually
lab-make health
# or
sudo bash /usr/local/bin/enhanced-health-check.sh

# Verify configuration
lab-make health-verify

# View logs
tail -f /var/log/enhanced-health-check.log

# Check timer status
systemctl status enhanced-health-check.timer

# Restart timer (if you updated the config)
sudo systemctl daemon-reload && sudo systemctl restart enhanced-health-check.timer
```

## ✅ Verification Checklist

- [ ] Timer file exists: `/etc/systemd/system/enhanced-health-check.timer`
- [ ] Service file exists: `/etc/systemd/system/enhanced-health-check.service`
- [ ] Timer interval is `1h`
- [ ] Timer is enabled: `systemctl is-enabled enhanced-health-check.timer`
- [ ] Timer is active: `systemctl is-active enhanced-health-check.timer`
- [ ] Script exists and is executable: `/usr/local/bin/enhanced-health-check.sh`
- [ ] Log file is being written: `/var/log/enhanced-health-check.log`

## 📝 Notes

- The health check runs **every hour**
- This should significantly reduce CPU usage
- The script checks multiple services and can restart them if they fail
- All actions are logged to `/var/log/enhanced-health-check.log`
