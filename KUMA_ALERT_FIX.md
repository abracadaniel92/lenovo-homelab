# Uptime Kuma Alert Fix

## Current Status

✅ **Kuma is running correctly:**
- Container is healthy
- HTTP access working
- Monitoring is active and detecting failures

❌ **Alerts are NOT being sent because:**
- `Down Count: 0` - Monitors haven't been down long enough to trigger alerts
- `Resend Interval: 0` - No resend configured, so alerts won't repeat

## The Problem

Kuma logs show:
```
[MONITOR] WARN: Monitor #X 'ServiceName': Failing: ... | Down Count: 0 | Resend Interval: 0
```

This means:
1. **Down Count: 0** - The monitor needs to fail multiple times before sending an alert (threshold not reached)
2. **Resend Interval: 0** - Even if an alert is sent, it won't resend (so you only get one alert)

## Solution

### Step 1: Configure Monitor Alert Settings

1. **Access Uptime Kuma:**
   - Go to `http://localhost:3001` (or your Kuma URL)
   - Log in

2. **For each monitor, click Edit and adjust:**
   - **Max Retries**: Set to `1` or `2` (send alert after 1-2 failures)
   - **Resend Interval**: Set to `60` or higher (resend alerts every X minutes while down)
   - **Upside Down Mode**: Enable if you want alerts when service comes back up

### Step 2: Configure Notification Channels

1. **Go to Settings > Notifications**

2. **Add notification channels:**
   - **Webhook** - For custom integrations (Slack, Discord, etc.)
   - **Email** - SMTP email notifications
   - **Telegram** - Telegram bot notifications
   - **Discord** - Discord webhook
   - **Slack** - Slack webhook
   - **Pushover** - Push notifications
   - **Gotify** - Self-hosted push notifications

3. **Example: Webhook for Slack/Discord:**
   ```
   Name: Slack Alerts
   Type: Webhook
   Webhook URL: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
   ```

### Step 3: Assign Notifications to Monitors

1. **Edit each monitor**
2. **Scroll to "Notifications" section**
3. **Select notification channels** to use for this monitor
4. **Save**

### Step 4: Test Notifications

1. **Manually trigger a test:**
   - Go to Settings > Notifications
   - Click "Test" next to each notification channel

2. **Or temporarily break a service** to verify alerts work

## Recommended Settings

### For Critical Services (Caddy, Cloudflare Tunnel):
- **Max Retries**: `1` (alert immediately)
- **Resend Interval**: `60` (resend every minute while down)
- **Notification**: Multiple channels (webhook + email)

### For Regular Services:
- **Max Retries**: `2` (allow 2 failures before alerting)
- **Resend Interval**: `300` (resend every 5 minutes)
- **Notification**: Webhook or email

## Quick Fix Commands

If you want to check Kuma status:
```bash
# Check container
docker ps | grep uptime-kuma

# Check logs
docker logs uptime-kuma --tail 50

# Restart if needed
cd /mnt/ssd/docker-projects/uptime-kuma
docker compose restart
```

## Verification

After configuring:

1. **Check monitor status** - All monitors should show notification channels assigned
2. **Test a notification** - Use the test button in notification settings
3. **Monitor logs** - Watch for notification messages:
   ```bash
   docker logs uptime-kuma | grep -i notification
   ```

## Why This Happened

The default Kuma settings are conservative:
- `Down Count: 0` means it needs multiple consecutive failures
- `Resend Interval: 0` means no repeat alerts
- No notification channels configured = no alerts sent

Once you configure these settings, Kuma will send alerts properly! 🚨

