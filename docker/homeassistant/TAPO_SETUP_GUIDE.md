# TP-Link Tapo Setup Guide for Home Assistant

Tapo devices (cameras, smart plugs, light bulbs) can be integrated with Home Assistant. Here's how:

## 📋 What You Need

- Tapo device IP address(es)
- Tapo account email and password
- Tapo app installed (for initial setup)

## Method 1: Built-in TP-Link Tapo Integration (Easiest)

Home Assistant has a built-in Tapo integration that works with most Tapo devices.

### Step 1: Find Your Tapo Device IP Address

**Option A - From Tapo App:**
1. Open Tapo app
2. Tap on your device
3. Go to Settings → Device Info
4. Note the IP address

**Option B - From Router:**
1. Log into router admin panel
2. Check connected devices
3. Look for "Tapo" devices

**Option C - From Server:**
```bash
# Scan network for Tapo devices
nmap -sn 192.168.1.0/24 | grep -i tapo

# Or check ARP table
arp -a | grep -i tapo
```

### Step 2: Add Integration in Home Assistant

1. **Open Home Assistant**: `http://192.168.1.97:8123`

2. **Go to Settings → Devices & Services**

3. **Click "Add Integration"** (bottom right)

4. **Search for "Tapo"** or **"TP-Link"**

5. **Select "TP-Link Tapo"** integration

6. **Enter credentials**:
   - **Host/IP**: Your Tapo device IP address
   - **Username**: Your Tapo account email
   - **Password**: Your Tapo account password

7. **Click Submit**

8. **Success!** Your Tapo device should appear in Home Assistant

### Step 3: Add Multiple Devices

If you have multiple Tapo devices:
1. Repeat Step 2 for each device
2. Or use YAML configuration (see Method 2)

## Method 2: YAML Configuration (For Multiple Devices)

For multiple Tapo devices, you can add them all at once:

### Edit configuration.yaml

```bash
cd /home/docker-projects/homeassistant
docker compose exec homeassistant nano /config/configuration.yaml
```

### Add Tapo Configuration

```yaml
tapo_control:
  - host: 192.168.1.XXX  # Camera 1 IP
    username: your@email.com
    password: your_password
  - host: 192.168.1.YYY  # Camera 2 IP
    username: your@email.com
    password: your_password
  - host: 192.168.1.ZZZ  # Smart Plug IP
    username: your@email.com
    password: your_password
```

### Restart Home Assistant

```bash
cd /home/docker-projects/homeassistant
docker compose restart
```

## Method 3: HACS Custom Integration (More Features)

For cameras with more features (streams, recording, etc.), use the custom Tapo integration:

### Step 1: Install via HACS

1. **Configure HACS** (if not done):
   - Settings → Devices & Services → HACS
   - Configure and accept terms

2. **Install Custom Integration**:
   - Go to **HACS** (sidebar or Settings)
   - Click **Integrations** tab
   - Click **Explore & Download Repositories**
   - Search for **"Tapo"** or **"TP-Link Tapo"**
   - Find **"Tapo (Cameras & HomeKit)"** by @JurajNyiri
   - Click **Download**
   - Restart Home Assistant

3. **Add Integration**:
   - Settings → Devices & Services → Add Integration
   - Search for **"Tapo"**
   - Enter device IP and credentials

## Supported Tapo Devices

### Cameras ✅
- Tapo C100, C200, C310, etc.
- Live streaming
- Motion detection
- PTZ control (if supported)
- Recording (with local storage)

### Smart Plugs ✅
- Tapo P100, P110, P115, etc.
- Power monitoring (if supported)
- On/off control
- Energy consumption tracking

### Smart Bulbs ✅
- Tapo L510, L530, etc.
- Color control
- Brightness control
- On/off control

### Other Devices ✅
- Door/window sensors
- Motion sensors
- Smart switches

## Features Available in Home Assistant

Once added, you'll have:

### For Cameras:
- **Camera stream**: View live feed in Home Assistant
- **Motion detection**: Get notifications when motion is detected
- **PTZ control**: Pan, tilt, zoom (if supported)
- **Recording status**: See if camera is recording
- **Night vision**: Control IR/night vision mode
- **Privacy mode**: Enable/disable privacy mode

### For Smart Plugs:
- **On/off control**: Turn devices on/off
- **Power monitoring**: Track energy consumption (if supported)
- **Schedule**: Create automations based on usage

### For Smart Bulbs:
- **Color control**: Change colors
- **Brightness**: Adjust brightness
- **Color temperature**: Warm/cool white
- **On/off control**: Turn lights on/off

## Troubleshooting

### Device Not Found

1. **Check Network**:
   ```bash
   ping 192.168.1.XXX  # Your Tapo device IP
   ```

2. **Check IP Address**:
   - Make sure device IP is correct
   - Set static IP on router for Tapo device

3. **Check Credentials**:
   - Verify email and password are correct
   - Make sure you're using your Tapo account, not Kasa account

### Integration Not Showing

1. **Try Different Search Terms**:
   - "Tapo"
   - "TP-Link"
   - "TP Link"

2. **Check Home Assistant Version**:
   - Tapo integration requires Home Assistant 2022.5 or later
   - Update if needed

3. **Restart Home Assistant**:
   ```bash
   cd /home/docker-projects/homeassistant
   docker compose restart
   ```

### Camera Stream Not Working

1. **Check Camera Settings**:
   - Enable RTSP stream in Tapo app (if using custom integration)
   - Enable local streaming

2. **Check Network**:
   - Ensure camera and Home Assistant are on same network
   - Check firewall settings

3. **Try Different Integration**:
   - Use HACS custom integration if built-in doesn't work
   - Custom integration has better streaming support

### Credentials Not Working

1. **Use Tapo Account**:
   - Make sure you're using Tapo account (not Kasa)
   - Tapo devices require Tapo account

2. **Reset Device** (if needed):
   - Hold reset button on device for 10 seconds
   - Re-add to Tapo app
   - Then add to Home Assistant

## Advanced: Local Control (No Cloud)

For better privacy and reliability, you can use local control:

1. **Enable Local Authentication** in Tapo app (if available)
2. **Use local credentials** instead of cloud account
3. **Set static IP** for Tapo device
4. **Use custom integration** which supports local streaming

## Useful Commands

```bash
# Find Tapo devices on network
nmap -sn 192.168.1.0/24 | grep -i tapo

# Test connection to camera
curl http://192.168.1.XXX/  # Tapo device IP

# Check Home Assistant logs
cd /home/docker-projects/homeassistant
docker compose logs | grep -i tapo
```

## Example Automation

```yaml
# Turn on smart plug when motion detected by Tapo camera
automation:
  - alias: "Tapo Motion - Turn on Light"
    trigger:
      - platform: state
        entity_id: binary_sensor.tapo_camera_motion
        to: 'on'
    action:
      - service: switch.turn_on
        entity_id: switch.tapo_smart_plug
```

## Resources

- Home Assistant Tapo Integration: https://www.home-assistant.io/integrations/tapo/
- HACS Tapo Integration: https://github.com/JurajNyiri/HomeAssistant-Tapo-Control
- Tapo Support: https://www.tp-link.com/support/

