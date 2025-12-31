# Uptime Kuma Notifications Setup

## Problem
No notifications received from Kuma when services went down.

## Solution
Kuma notifications must be configured manually in the web UI.

## Step-by-Step Setup

### Step 1: Access Uptime Kuma
1. Open: http://localhost:3001 (or https://your-kuma-domain if configured)
2. Login with your admin credentials

### Step 2: Configure Notification Method

1. **Go to Settings** (gear icon in top right)
2. **Click "Notifications"** in the left sidebar
3. **Click "Add Notification"**
4. **Choose notification type**:
   - **Telegram** (recommended - instant, free)
   - **Email** (SMTP required)
   - **Discord** (webhook)
   - **Slack** (webhook)
   - **Pushover** (mobile push)
   - **Gotify** (self-hosted push)
   - **Webhook** (custom)

### Step 3: Configure Telegram (Recommended)

1. **Create Telegram bot**:
   - Message @BotFather on Telegram
   - Send `/newbot`
   - Follow instructions to create bot
   - Save the **bot token**

2. **Get your chat ID**:
   - Message your bot
   - Visit: https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates
   - Find your `chat.id` in the response

3. **Add to Kuma**:
   - Notification Type: **Telegram**
   - Bot Token: `<your-bot-token>`
   - Chat ID: `<your-chat-id>`
   - Click "Test" to verify
   - Click "Save"

### Step 4: Enable Notifications for Monitors

1. **Go to Monitors** (main page)
2. **For each monitor**:
   - Click the **three dots (⋮)** on the monitor
   - Click **"Edit"**
   - Scroll to **"Notifications"** section
   - **Enable the notification method** you created
   - Click **"Save"**

### Step 5: Test Notifications

1. **Manually trigger a test**:
   - Go to monitor → Three dots → "Test Notification"
   - Or temporarily disable a service to trigger alert

2. **Verify you receive notification**

## Quick Setup Commands

### Check Kuma Status
```bash
docker ps | grep kuma
docker logs uptime-kuma --tail 50
```

### Access Kuma
- Local: http://localhost:3001
- External: https://your-kuma-domain (if configured)

## Common Notification Types

### Telegram (Recommended)
- **Pros**: Instant, free, mobile app
- **Setup**: Bot token + Chat ID
- **Best for**: Personal monitoring

### Email
- **Pros**: Works everywhere
- **Setup**: SMTP server required
- **Best for**: Multiple recipients

### Discord
- **Pros**: Team notifications
- **Setup**: Webhook URL
- **Best for**: Team alerts

### Pushover
- **Pros**: Mobile push notifications
- **Setup**: User key + API token
- **Best for**: Mobile-first alerts

## Troubleshooting

### Notifications Not Sending

1. **Check notification is enabled**:
   - Monitor → Edit → Notifications → Enabled

2. **Test notification manually**:
   - Monitor → Three dots → "Test Notification"

3. **Check Kuma logs**:
   ```bash
   docker logs uptime-kuma --tail 100 | grep -i notification
   ```

4. **Verify notification method**:
   - Settings → Notifications → Test button

### Telegram Bot Not Working

1. **Verify bot token is correct**
2. **Check chat ID is correct**
3. **Make sure you've messaged the bot first**
4. **Test with curl**:
   ```bash
   curl "https://api.telegram.org/bot<TOKEN>/sendMessage?chat_id=<CHAT_ID>&text=Test"
   ```

## Best Practices

1. **Use multiple notification methods** (Telegram + Email)
2. **Test after setup** (manually trigger alert)
3. **Enable for all critical monitors**
4. **Set up different notifications for different severity levels**

## Expected Behavior

After setup:
- ✅ Receive notification when service goes down
- ✅ Receive notification when service recovers
- ✅ Receive notification on status changes
- ✅ Can test notifications manually

## Related

- `MONITORING_AND_RECOVERY.md` - Overall monitoring system
- `AUTO_DOWNTIME_FIX.md` - Automatic downtime fixing

