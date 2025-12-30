# 🚨 CRITICAL: Uptime Kuma Not Sending Alerts

## Problem
Uptime Kuma is detecting service failures but **NOT sending alerts** because:
- **Resend Interval: 0** = Alerts are disabled
- Monitors are configured but notifications are not set up

## Solution

### Step 1: Configure Notifications in Uptime Kuma

1. **Access Uptime Kuma**: https://status.gmojsoski.com (or http://localhost:3001)

2. **Go to Settings → Notifications**

3. **Add a notification method** (choose one or more):
   - **Email** (recommended)
   - **Telegram Bot**
   - **Discord Webhook**
   - **Slack Webhook**
   - **Pushover**
   - **Gotify**

4. **Test the notification** to ensure it works

### Step 2: Configure Each Monitor

For **EACH monitor** that's failing:

1. **Click on the monitor** (e.g., "TravelSync", "Nextcloud", etc.)

2. **Go to "Notifications" tab**

3. **Select your notification method** (the one you configured in Step 1)

4. **Set "Resend Interval"**:
   - **Recommended: 60 minutes** (or 30 minutes for critical services)
   - **This is the time between alert resends when a service is down**
   - **0 = No alerts will be sent!**

5. **Set "Max Retries"**:
   - **Recommended: 3-5** (how many times to check before alerting)
   - This prevents false positives from temporary network hiccups

6. **Click "Save"**

### Step 3: Verify Alert Configuration

1. **Check monitor status** - All monitors should show:
   - ✅ Notification method selected
   - ✅ Resend Interval > 0 (e.g., 60 minutes)
   - ✅ Max Retries > 0 (e.g., 3)

2. **Test an alert**:
   - Temporarily stop a service (e.g., `docker stop caddy`)
   - Wait for the monitor to detect it (check "Max Retries" countdown)
   - You should receive an alert
   - Restart the service: `docker start caddy`

### Quick Fix for All Monitors

If you have many monitors, you can use the **bulk edit** feature:

1. **Go to Dashboard**
2. **Select multiple monitors** (checkboxes)
3. **Click "Bulk Edit"**
4. **Set "Resend Interval"** to 60 minutes
5. **Select notification method**
6. **Click "Save"**

## Why This Happened

The monitors were created but notifications were never configured. Uptime Kuma needs:
1. A notification method (email, Telegram, etc.)
2. Each monitor linked to that notification
3. Resend Interval > 0 (otherwise no alerts are sent)

## Current Status

All monitors show: **"Resend Interval: 0"** = **NO ALERTS**

This must be fixed manually in the Uptime Kuma UI.

## After Fixing

Once configured, you'll receive alerts when:
- Services go down
- Services are unreachable
- Services return to normal (optional "recovery" notification)

**You should receive alerts within 3-5 minutes of a service failure** (depending on Max Retries setting).
