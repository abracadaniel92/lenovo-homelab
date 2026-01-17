# Pi Alert - Network Monitoring with Mattermost Integration

Pi Alert monitors your network, discovers devices, and sends alerts to Mattermost when devices join/leave or IP addresses change.

## Features

- **Device Discovery**: Automatically scans and discovers all devices on your network
- **Change Detection**: Alerts when new devices join, devices disconnect, or IP addresses change
- **Pi-hole Integration**: Reads DHCP leases from Pi-hole for better device tracking
- **Mattermost Webhooks**: Sends alerts directly to your Mattermost channels
- **Dashboard**: Web UI to view all devices, history, and network statistics

## Setup

### 1. Start Pi Alert

```bash
cd /path/to/repo/docker/pi-alert
docker compose up -d
```

### 2. Access Pi Alert Web UI

- Open: `http://your-pi-ip:20211`
- Default credentials: `admin` / `12345678` (change immediately!)

### 3. Configure Mattermost Webhook

1. **Create Mattermost Webhook**:
   - Go to Mattermost: `https://mattermost.gmojsoski.com`
   - Log in to your Mattermost account
   - Go to: **Integrations** → **Incoming Webhooks**
   - Click **Add Incoming Webhook**
   - Select the channel where you want alerts (e.g., "Network Alerts" channel)
   - Copy the **Webhook URL** (format: `https://mattermost.gmojsoski.com/hooks/xxxxx`)
   - Save the webhook URL for later

2. **Configure in Pi Alert**:
   - Access Pi Alert web UI: `http://your-pi-ip:20211`
   - Default login: `admin` / `12345678` (**change immediately!**)
   - Go to: **Settings** → **Notifications** → **Webhook Publisher**
   - Enable **Webhook** publisher plugin
   - Click **Add Webhook** or configure existing webhook:
     - **Webhook URL**: Paste your Mattermost webhook URL
     - **Payload Format**: JSON (Mattermost expects JSON)
   - Test webhook (should send a test message to Mattermost channel)
   - Configure which events trigger alerts (see below)
   - Save settings

### 4. Configure Pi-hole Integration

Pi Alert can read DHCP leases from Pi-hole for better device discovery:

1. **In Pi Alert Web UI**:
   - Go to: **Settings** → **Network Scan**
   - Enable **Pi-hole Integration**
   - Pi-hole Host: `localhost` (already configured)
   - Pi-hole Path: `/etc/pihole` (default)
   - Save settings

2. **Grant Pi Alert access to Pi-hole** (if needed):
   ```bash
   # If Pi Alert can't read Pi-hole files, you may need to adjust permissions
   # or mount Pi-hole volumes (usually not needed with host network)
   ```

### 5. Configure Network Scanning

1. **In Pi Alert Web UI**:
   - Go to: **Settings** → **Network Scan**
   - Set **Network Range**: `192.168.1.0/24` (adjust to your network)
   - Set **Scan Interval**: `300` seconds (5 minutes) - adjust as needed
   - Enable **ARP Scan**: `true`
   - Enable **Pi-hole DHCP Leases**: `true`
   - Save settings

## Alert Types

Pi Alert will send Mattermost notifications for:

- **New Device**: When a new device joins your network
- **Device Disconnected**: When a device goes offline
- **Device Reconnected**: When a device comes back online
- **IP Changed**: When a device gets a new IP address
- **Public IP Changed**: When your router's public IP changes

## Mattermost Webhook Format

Pi Alert sends alerts in JSON format. Mattermost will receive:
- **Channel**: The channel where the webhook was created
- **Username**: Pi Alert
- **Message**: Alert details (device name, IP, MAC address, event type)

Example alert:
```
🔔 New Device Detected
Device: iPhone (John's Phone)
IP: 192.168.1.105
MAC: aa:bb:cc:dd:ee:ff
Time: 2026-01-17 15:45:30
```

## Customization

### Customize Alert Messages

You can customize alert messages in Pi Alert:
- Go to: **Settings** → **Notifications** → **Webhook Publisher**
- Configure payload format for Mattermost (if custom format needed)
- Mattermost expects JSON format like:
  ```json
  {
    "text": "🔔 New Device Detected\nDevice: iPhone\nIP: 192.168.1.105"
  }
  ```

### Configure Alert Events

Choose which events trigger Mattermost notifications:
- Go to: **Settings** → **Notifications**
- Enable/disable:
  - ✅ New Device Detected
  - ✅ Device Disconnected
  - ✅ Device Reconnected
  - ✅ IP Address Changed
  - ✅ Public IP Changed
  - ✅ Ignore List (devices to skip alerts)

### Integration with Existing Services

Pi Alert can also:
- Integrate with Home Assistant (if you add it later)
- Send email notifications
- Use custom notification scripts
- Export data via API

## Troubleshooting

### Pi Alert not discovering devices

1. **Check network scan settings**:
   - Verify network range matches your LAN (`192.168.1.0/24`)
   - Ensure ARP scan is enabled
   - Check Pi-hole integration is enabled

2. **Check permissions**:
   ```bash
   docker logs pi-alert
   # Look for permission errors
   ```

3. **Test network scan manually**:
   ```bash
   docker exec pi-alert arp-scan --local
   # Or check if devices are visible to Pi Alert
   ```

### Mattermost webhook not working

1. **Test webhook URL**:
   ```bash
   curl -X POST -H 'Content-Type: application/json' \
     -d '{"text":"Test from Pi Alert"}' \
     YOUR_WEBHOOK_URL
   ```

2. **Check Pi Alert logs**:
   ```bash
   docker logs pi-alert | grep -i webhook
   ```

3. **Verify webhook in Mattermost**:
   - Check webhook is enabled in Mattermost
   - Verify webhook URL is correct
   - Check Mattermost logs for incoming webhook errors

### Pi-hole integration not working

Since both containers use `network_mode: host`, Pi Alert should be able to access Pi-hole directly. If not:

1. **Check Pi-hole is running**:
   ```bash
   docker ps | grep pihole
   ```

2. **Verify Pi-hole files are accessible**:
   ```bash
   docker exec pi-alert ls -la /etc/pihole/
   # Should show Pi-hole files if host network is working
   ```

## Resource Usage

- **RAM**: ~50-100MB
- **CPU**: Minimal (scans run on intervals)
- **Disk**: ~100MB (database for device history)

Perfect for Raspberry Pi 4 with 4GB RAM.

## Security Notes

- Change default admin password immediately!
- Pi Alert runs with host network access (needed for scanning)
- Webhook URLs contain secrets - keep them secure
- Consider limiting webhook to specific Mattermost channels

## Next Steps

After setup:
1. Change default password
2. Configure Mattermost webhook
3. Let it scan for 24 hours to build device inventory
4. Mark known devices as "favorites" in the dashboard
5. Set up automation rules if needed

Enjoy monitoring your network! 🎯

