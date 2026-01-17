# Pi Alert Quick Setup Guide

## Step 1: First Login & Change Password

1. Access Pi Alert: `http://192.168.1.98:20211`
2. Login with:
   - **Username**: `admin`
   - **Password**: `12345678`
3. **IMPORTANT**: Change password immediately!
   - Go to: **Settings** → **User Management** → Change password

## Step 2: Configure Mattermost Webhook

1. **In Pi Alert Web UI**:
   - Go to: **Settings** → **Notifications** → **Webhook Publisher**
   - Click **Enable** or **Add Webhook**
   - **Webhook URL**: `https://mattermost.gmojsoski.com/hooks/jdyxig47nt8hig5se9cokndbey`
   - **Format**: JSON (Mattermost expects JSON)
   - Click **Test** - should send a test message to Mattermost
   - **Save**

2. **Configure Alert Events**:
   - Go to: **Settings** → **Notifications**
   - Enable notifications for:
     - ✅ New Device Detected
     - ✅ Device Disconnected
     - ✅ Device Reconnected
     - ✅ IP Address Changed
     - ✅ Public IP Changed (optional)

## Step 3: Configure Network Scanning

1. **Go to**: **Settings** → **Network Scan**

2. **Network Configuration**:
   - **Network Range**: `192.168.1.0/24` (adjust if your network is different)
   - **Scan Interval**: `300` seconds (5 minutes) - adjust as needed
   - **ARP Scan**: Enable
   - **Ping Scan**: Enable (optional)

3. **Pi-hole Integration** (Optional - ARP scan works without it):
   - **Enable Pi-hole Plugin**:
     - Go to: **Settings → Core → LOADED_PLUGINS**
     - Add `PIHOLE_SCAN` to the list
     - Save and refresh page
   - **Configure Pi-hole Plugin**:
     - Go to: **Settings → Plugins → PiHole Scan** (appears after enabling)
     - **Pi-hole Host**: `localhost`
     - **Pi-hole Path**: `/etc/pihole`
     - **Schedule**: Same as ARP scan (e.g., `*/5 * * * *`)
   - **Note**: Pi-hole integration is optional - ARP scan will discover devices without it

## Step 4: Let It Scan

1. **Initial Scan**:
   - Pi Alert will start scanning your network
   - First scan may take 5-10 minutes
   - Go to **Dashboard** to see discovered devices

2. **Mark Known Devices**:
   - As devices are discovered, mark them as "Known" or "Favorite"
   - This reduces false alerts for devices you recognize
   - Go to: **Devices** → Click device → Mark as Favorite

3. **Ignore List** (Optional):
   - If you want to ignore certain devices (e.g., IoT devices that connect/disconnect frequently)
   - Go to: **Settings** → **Notifications** → **Ignore List**
   - Add MAC addresses or IPs to ignore

## Step 5: Verify Mattermost Integration

1. **Test Webhook**:
   - In Pi Alert: **Settings** → **Notifications** → **Webhook Publisher**
   - Click **Test Webhook**
   - Check Mattermost channel - you should see a test message

2. **Trigger Test Alert**:
   - Disconnect a device from WiFi
   - Reconnect it
   - You should see alerts in Mattermost

## What You'll See in Mattermost

When events occur, you'll get messages like:

```
🔔 New Device Detected
Device: iPhone (John's Phone)
IP: 192.168.1.105
MAC: aa:bb:cc:dd:ee:ff
Time: 2026-01-17 16:00:00
```

Or:

```
⚠️ Device Disconnected
Device: Laptop (Work Laptop)
IP: 192.168.1.120
Last Seen: 2026-01-17 15:55:00
```

## Troubleshooting

### Webhook Not Working
- Verify webhook URL is correct
- Test webhook manually:
  ```bash
  curl -X POST -H 'Content-Type: application/json' \
    -d '{"text":"Test"}' \
    https://mattermost.gmojsoski.com/hooks/jdyxig47nt8hig5se9cokndbey
  ```
- Check Pi Alert logs: `docker logs pi-alert`

### Not Discovering Devices
- Verify network range matches your LAN (`192.168.1.0/24`)
- Check Pi-hole integration is enabled
- Ensure ARP scan is enabled
- Check firewall isn't blocking scans

### Too Many Alerts
- Mark known devices as "Favorite" to reduce alerts
- Add frequently connecting/disconnecting devices to Ignore List
- Adjust notification settings to only alert on important events

## Next Steps

After setup:
1. Let Pi Alert run for 24 hours to build device inventory
2. Review discovered devices and mark known ones
3. Fine-tune alert settings based on your needs
4. Set up device naming for better identification

Enjoy monitoring your network! 🎯

