# Uptime Kuma + ntfy.sh Notifications Setup

Simple guide to configure Uptime Kuma to send alerts via ntfy.sh (free push notifications).

---

## What is ntfy.sh?

- **Free** push notification service
- **No account required** for basic usage
- **Mobile apps** available (iOS, Android)
- **Web dashboard** for viewing notifications
- **Self-hostable** (optional)

---

## Step 1: Subscribe to a Topic

1. **Visit**: https://ntfy.sh/
2. **Choose a topic name** (e.g., `lemongrab-alerts` or your unique name)
   - Topics are public by default (anyone can subscribe)
   - Use a random/unique name for privacy
3. **Subscribe**:
   - **Web**: Visit `https://ntfy.sh/<your-topic-name>`
   - **Mobile**: Install ntfy app and subscribe to `lemongrab-alerts`
   - **Command line**: `curl -s ntfy.sh/<your-topic-name>`

**Example topic**: `lemongrab-alerts-xyz123` (use something unique)

---

## Step 2: Get Your Topic URL

Your webhook URL will be:
```
https://ntfy.sh/<your-topic-name>
```

**Example**: `https://ntfy.sh/lemongrab-alerts-xyz123`

---

## Step 3: Configure in Uptime Kuma

1. **Access Uptime Kuma**:
   - Open: http://localhost:3001
   - Or your external URL if configured

2. **Go to Settings**:
   - Click the **gear icon** (⚙️) in top right
   - Click **"Notifications"** in left sidebar

3. **Add Webhook Notification**:
   - Click **"+ Add"** button
   - Select **"Webhook"** type
   - Fill in:
     - **Name**: `ntfy.sh Alerts` (or any name)
     - **Webhook URL**: `https://ntfy.sh/<your-topic-name>`
     - **HTTP Method**: `POST`
     - **Content Type**: `application/json` (optional, ntfy works with plain text too)

4. **Optional: Customize Payload**:
   - Click **"Advanced"** or **"Customize Payload"**
   - You can customize the JSON payload if needed
   - **Default** (if no customization):
     ```json
     {
       "title": "{{name}}",
       "message": "{{message}}",
       "priority": "{{priority}}",
       "tags": ["{{status}}"]
     }
     ```
   - **Simple version** (just works):
     - Leave defaults, or set:
     ```json
     {
       "title": "Uptime Kuma Alert",
       "message": "{{message}}",
       "priority": "default"
     }
     ```

5. **Test the Notification**:
   - Click **"Test"** button
   - You should receive a notification on your subscribed devices/apps
   - If not working, check the webhook URL

6. **Save**:
   - Click **"Save"** button

---

## Step 4: Enable for Monitors

For **each monitor** you want to alert on:

1. **Go to Monitors** (main dashboard)
2. **Click on a monitor** (or click three dots → Edit)
3. **Scroll to "Notifications" section**
4. **Enable your notification**:
   - Check the box for `ntfy.sh Alerts`
   - **Resend Interval**: `60` (minutes) - resend alert every hour while down
   - **Max Retries**: `3` - wait 3 failures before alerting
5. **Save**

---

## Step 5: Test Full Flow

1. **Temporarily stop a service**:
   ```bash
   docker stop caddy
   ```

2. **Wait for alert**:
   - Uptime Kuma will check the service
   - After "Max Retries" failures, it will send alert
   - You should receive notification on ntfy.sh

3. **Restart service**:
   ```bash
   docker start caddy
   ```

4. **Verify recovery notification** (if enabled)

---

## Alternative: Simple Text Format

If you want simpler notifications, you can use **GET request** instead:

1. **In Uptime Kuma notification settings**:
   - **Webhook URL**: `https://ntfy.sh/<your-topic-name>`
   - **HTTP Method**: `GET`
   - **Query Parameters**:
     ```
     title={{name}}&message={{message}}&priority=default
     ```

Or use **curl format** in Advanced:
```
https://ntfy.sh/<your-topic-name>?title={{name}}&message={{message}}&priority=default
```

---

## Priority Levels

You can set different priorities for different alerts:
- `default` - Normal alert
- `low` - Less urgent
- `high` - More urgent  
- `urgent` - Very urgent (triggers sound/vibration)

In custom payload:
```json
{
  "priority": "{{#if status == 'down'}}urgent{{else}}default{{/if}}"
}
```

---

## Self-Hosted ntfy (Optional)

If you want to self-host ntfy:

1. **Docker Compose example**:
   ```yaml
   services:
     ntfy:
       image: binwiederhier/ntfy
       ports:
         - "8080:80"
       volumes:
         - ./ntfy_cache:/var/cache/ntfy
   ```

2. **Use your own URL**:
   - Webhook URL: `http://your-ntfy-server:8080/<topic-name>`

---

## Troubleshooting

### Not Receiving Notifications

1. **Check topic subscription**:
   - Visit `https://ntfy.sh/<your-topic-name>` in browser
   - You should see a live feed
   - Send test: `curl -d "Test" https://ntfy.sh/<your-topic-name>`

2. **Check Uptime Kuma logs**:
   ```bash
   docker logs uptime-kuma --tail 50 | grep -i notification
   ```

3. **Test webhook manually**:
   ```bash
   curl -X POST https://ntfy.sh/<your-topic-name> \
     -H "Content-Type: application/json" \
     -d '{"title":"Test","message":"Testing from command line"}'
   ```

4. **Verify monitor settings**:
   - Notification is enabled
   - Resend Interval > 0
   - Max Retries > 0

### Mobile App Not Working

1. **Install ntfy app** from App Store / Play Store
2. **Subscribe to topic**: `lemongrab-alerts-xyz123`
3. **Grant notification permissions**
4. **Test with curl** to verify

---

## Security Note

⚠️ **Topics are public** by default on ntfy.sh:
- Anyone who knows your topic name can see notifications
- Use a **random/unique topic name** (not predictable)
- Or use **self-hosted ntfy** with authentication
- Or use **ntfy Pro** for private topics

**Recommendation**: Use a random topic name like `lemongrab-alerts-k8x9m2p4`

---

## Quick Reference

| Setting | Value |
|---------|-------|
| **Notification Type** | Webhook |
| **Webhook URL** | `https://ntfy.sh/<your-topic-name>` |
| **HTTP Method** | POST |
| **Content Type** | application/json |
| **Resend Interval** | 60 minutes |
| **Max Retries** | 3 |

---

## Next Steps

After setup:
1. ✅ Test notifications work
2. ✅ Enable for all critical monitors
3. ✅ Monitor on mobile device
4. ✅ Consider self-hosting for privacy (optional)

---

*Last updated: January 2026*

