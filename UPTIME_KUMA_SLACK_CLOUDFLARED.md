# Uptime Kuma - Slack Notifications for Cloudflared

Yes! Uptime Kuma can send Slack notifications when cloudflared is down, just like it does for Caddy.

## Quick Setup

### Step 1: Add Cloudflared Monitor

1. Open Uptime Kuma: `http://localhost:3001`
2. Click **"Add New Monitor"**
3. Configure:
   - **Monitor Type**: HTTP(s) - Keyword
   - **Friendly Name**: `Cloudflared Tunnel Status`
   - **URL**: `https://gmojsoski.com`
   - **Interval**: 60 seconds
   - **Retry Interval**: 30 seconds
   - **Max Retries**: 3
   - **Keyword**: `gmojsoski` (or any text that should appear on your site)
   - **Expected Status Code**: 200

### Step 2: Configure Slack Notifications

#### Option A: Use Existing Slack Notification (Recommended)

If you already have Slack notifications set up for Caddy:

1. Go to **Settings** → **Notifications**
2. Find your existing Slack notification
3. Make sure it's enabled
4. When creating the Cloudflared monitor, select this Slack notification in the **"Notify"** section

#### Option B: Create New Slack Notification

1. Go to **Settings** → **Notifications**
2. Click **"Add Notification"**
3. Select **"Slack"**
4. Configure:
   - **Friendly Name**: `Slack Alerts`
   - **Webhook URL**: Your Slack webhook URL
     - Format: `https://hooks.slack.com/services/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`
   - **Channel**: `#alerts` (optional, defaults to webhook channel)
   - **Username**: `Uptime Kuma` (optional)
   - **Icon Emoji**: `:warning:` (optional)

5. Click **"Test"** to verify it works
6. Click **"Save"**

### Step 3: Link Notification to Monitor

When creating or editing your Cloudflared monitor:

1. Scroll down to **"Notify"** section
2. Select your Slack notification
3. Choose when to notify:
   - ✅ **When Down**: Get notified when cloudflared goes down
   - ✅ **When Up**: Get notified when cloudflared comes back up (optional)
   - ✅ **When Certificate Expires**: Not applicable for HTTP endpoints

4. Click **"Save"**

## Alternative: Monitor Cloudflared Metrics Endpoint

You can also monitor the metrics endpoint directly:

1. **Monitor Type**: HTTP(s)
2. **URL**: `http://192.168.1.97:20241/metrics` (use your host IP)
3. **Expected Status Code**: 200
4. **Keyword**: `cloudflared` (should appear in metrics output)

This checks if cloudflared process is running, but monitoring the public endpoint (`https://gmojsoski.com`) is better because it checks the entire chain.

## Notification Settings

### Recommended Settings

- **Interval**: 60 seconds (check every minute)
- **Retry Interval**: 30 seconds (retry quickly)
- **Max Retries**: 3 (don't spam)
- **Notify When Down**: ✅ Yes
- **Notify When Up**: ✅ Yes (so you know when it's fixed)

### Advanced: Multiple Notifications

You can set up multiple notification channels:
- Slack for immediate alerts
- Email for backup
- Discord, Telegram, etc.

## Testing

1. **Test Notification**: In Uptime Kuma, go to your monitor → Click **"Test"** button
2. **Test Manually**: Temporarily stop cloudflared:
   ```bash
   sudo systemctl stop cloudflared.service
   ```
   Wait 1-2 minutes, you should get a Slack notification
3. **Restart**: 
   ```bash
   sudo systemctl start cloudflared.service
   ```
   You should get an "up" notification

## Slack Message Format

Uptime Kuma will send messages like:

```
🚨 Cloudflared Tunnel Status is DOWN
https://gmojsoski.com
Status Code: 502
```

And when it comes back up:

```
✅ Cloudflared Tunnel Status is UP
https://gmojsoski.com
Status Code: 200
```

## Troubleshooting

### Notifications Not Working?

1. **Check Notification Status**: Settings → Notifications → Make sure it's enabled
2. **Test Webhook**: Click "Test" button in notification settings
3. **Check Monitor**: Make sure monitor is active and notifications are enabled
4. **Check Slack**: Verify webhook URL is correct in Slack app settings

### Webhook URL

If you need to create a new Slack webhook:
1. Go to https://api.slack.com/apps
2. Select your workspace
3. Go to "Incoming Webhooks"
4. Create new webhook
5. Copy the webhook URL

## Comparison: Caddy vs Cloudflared Monitoring

| Monitor | URL | What It Checks |
|---------|-----|----------------|
| **Caddy** | `http://localhost:8080` | Caddy reverse proxy is running |
| **Cloudflared** | `https://gmojsoski.com` | Full chain: Cloudflare → Tunnel → Caddy → Site |

**Best Practice**: Monitor both!
- **Caddy monitor**: Catches Caddy-specific issues
- **Cloudflared monitor**: Catches tunnel and full-stack issues

Both can use the same Slack notification channel.

