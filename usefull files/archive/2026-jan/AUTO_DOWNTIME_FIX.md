# Automatic Downtime Detection and Fix

## What Was Added

The `enhanced-health-check.sh` script now **automatically detects and fixes subdomain downtime**.

## How It Works

Every 30 seconds, the health check:

1. **Checks local services** (Caddy, Docker, etc.)
2. **Checks external access** (tests https://gmojsoski.com)
3. **If external access is down but local services work**:
   - Automatically restarts Caddy
   - Automatically restarts Cloudflare tunnel
   - Verifies the fix worked
   - Logs everything

## Setup

### Step 1: Update the Health Check Script

The script has been updated in the repo. To install it:

```bash
sudo cp "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/enhanced-health-check.sh" /usr/local/bin/enhanced-health-check.sh
sudo chmod +x /usr/local/bin/enhanced-health-check.sh
```

### Step 2: Restart the Health Check Timer

```bash
sudo systemctl restart enhanced-health-check.timer
```

### Step 3: Verify It's Working

```bash
# Check logs to see if it's detecting and fixing downtime
tail -f /var/log/enhanced-health-check.log
```

## What Gets Fixed Automatically

When downtime is detected, the script automatically:

1. ✅ **Restarts Caddy** (reverse proxy)
2. ✅ **Restarts Cloudflare Tunnel** (external access)
3. ✅ **Waits for services to recover**
4. ✅ **Verifies the fix worked**

## Limitations

### Sudo Requirement

The Cloudflare tunnel restart requires `sudo`. The script will try to restart it, but if sudo isn't configured for passwordless access, you may see warnings in the logs.

### To Enable Passwordless Sudo (Optional)

If you want the fix to work completely automatically without sudo prompts:

```bash
# Add to sudoers (allows restarting cloudflared without password)
echo "goce ALL=(ALL) NOPASSWD: /bin/systemctl restart cloudflared.service" | sudo tee /etc/sudoers.d/cloudflared-restart
```

**Security Note**: This only allows restarting the cloudflared service, not full sudo access.

## Monitoring

### Check Logs

```bash
# View recent health checks
tail -50 /var/log/enhanced-health-check.log

# Follow logs in real-time
tail -f /var/log/enhanced-health-check.log

# Search for downtime fixes
grep "External access" /var/log/enhanced-health-check.log
```

### Expected Log Messages

When downtime is detected and fixed:
```
[2025-12-31 08:00:00] WARNING: External access down (gmojsoski.com not accessible, but local services OK)
[2025-12-31 08:00:00] Attempting automatic fix...
[2025-12-31 08:00:00] Restarting Caddy...
[2025-12-31 08:00:05] Restarting Cloudflare tunnel...
[2025-12-31 08:00:15] SUCCESS: External access restored after automatic fix
```

## Manual Override

If automatic fix doesn't work, you can still run the fix script manually:

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-subdomains-down.sh"
```

## Testing

To test if automatic fix is working:

1. **Manually break something** (restart Caddy or Cloudflare tunnel)
2. **Wait 30-60 seconds** (for health check to run)
3. **Check logs** to see if it detected and fixed:
   ```bash
   tail -20 /var/log/enhanced-health-check.log
   ```

## Status

- ✅ **Automatic detection**: Enabled
- ✅ **Automatic Caddy restart**: Works
- ⚠️ **Automatic Cloudflare restart**: Requires sudo (may need passwordless sudo setup)

## Related Scripts

- `enhanced-health-check.sh` - Main health check with auto-fix
- `fix-subdomains-down.sh` - Manual fix script (more comprehensive)
- `fix-all-services.sh` - Complete service recovery




