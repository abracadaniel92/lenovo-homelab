# Uptime Kuma Alert Verification Checklist

## Why Bookmarks Alert Didn't Fire

If Uptime Kuma shows a service as "up" but it's actually down, check these:

### 1. ✅ Check Monitor Configuration

**Access Kuma**: http://localhost:3001

**For each monitor (especially bookmarks):**

1. **Click on the monitor** → **Edit**
2. **Check the URL**:
   - ❌ **Wrong**: `http://localhost:5000` (only checks internal)
   - ✅ **Correct**: `https://bookmarks.gmojsoski.com` (checks external access)
3. **Check "Max Retries"**:
   - If set to `10`, it won't alert until 10 consecutive failures
   - **Recommended**: `3` (alert after 3 failures)
4. **Check "Interval"**:
   - How often it checks (e.g., 60 seconds)
   - **Recommended**: `60` seconds

### 2. ✅ Check Notifications Are Enabled

**For each monitor:**

1. **Edit monitor** → Scroll to **"Notifications"** section
2. **Verify notification is checked/enabled**
3. **Check "Resend Interval"**:
   - How often to resend alert while service is down
   - **Recommended**: `60` minutes (resend every hour)

### 3. ✅ Verify Notification Method Exists

**Go to Settings** → **Notifications**:

1. **Check if any notification methods are configured**:
   - Telegram
   - Slack
   - Email
   - Webhook
   - etc.
2. **If none exist**: Follow `KUMA_NOTIFICATIONS_SETUP.md` to set one up

### 4. ✅ Test Notification Manually

1. **Go to monitor** → **Three dots (⋮)** → **"Test Notification"**
2. **If test fails**: Notification method is misconfigured
3. **If test succeeds**: Monitor might not be checking the right endpoint

### 5. ✅ Check Monitor is Actually Monitoring

**Common Issues:**

| Issue | Symptom | Fix |
|-------|---------|-----|
| **Wrong URL** | Monitor shows "up" but service is down externally | Change URL to external domain |
| **Too many retries** | Service down for hours, no alert | Reduce "Max Retries" to 3 |
| **Notifications disabled** | Monitor shows "down" but no alert | Enable notifications in monitor settings |
| **No notification method** | Can't enable notifications | Set up notification method first |

### 6. ✅ Recommended Monitor Settings

**For bookmarks.gmojsoski.com:**

```
Name: Bookmarks
URL: https://bookmarks.gmojsoski.com
Type: HTTP(s) - Keyword
Keyword: (leave empty or set to "200")
Interval: 60 seconds
Max Retries: 3
Notifications: [Your notification method] ✓ Enabled
Resend Interval: 60 minutes
```

### 7. ✅ Quick Verification Commands

```bash
# Check if Kuma is running
docker ps | grep kuma

# Check Kuma logs for errors
docker logs uptime-kuma --tail 50

# Test bookmarks externally
curl -I https://bookmarks.gmojsoski.com

# Test bookmarks internally
curl -I http://localhost:5000
```

### 8. ✅ Why Health Check Caught It But Kuma Didn't

**Health Check** (`enhanced-health-check.sh`):
- Checks **internal** services (`localhost:5000`)
- Runs every **30 seconds**
- Auto-restarts services
- ✅ **Caught bookmarks down** (internal check)

**Uptime Kuma**:
- Should check **external** access (`https://bookmarks.gmojsoski.com`)
- Runs every **60 seconds** (configurable)
- Only alerts, doesn't fix
- ❌ **Didn't catch it** (likely wrong URL or notifications disabled)

### 9. ✅ Action Items

1. **Verify bookmarks monitor URL** is `https://bookmarks.gmojsoski.com` (not localhost)
2. **Check notifications are enabled** for bookmarks monitor
3. **Set up notification method** if none exists (see `KUMA_NOTIFICATIONS_SETUP.md`)
4. **Reduce Max Retries** to 3 for faster alerts
5. **Test notification** manually to verify it works

### 10. ✅ Integration with Slack

Since you're using Slack for health check alerts, consider:

1. **Add Slack webhook to Kuma**:
   - Settings → Notifications → Add → Slack
   - Use same `MONITORING_SLACK_WEBHOOK_URL` from `scripts/.env`
2. **Enable for all monitors**
3. **Get alerts in same Slack channel** as health check

---

**Next Steps:**
1. Access Kuma: http://localhost:3001
2. Check bookmarks monitor configuration
3. Verify notifications are enabled
4. Test notification manually
5. Consider adding Slack integration







