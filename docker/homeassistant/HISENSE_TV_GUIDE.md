# Adding Hisense TV to Home Assistant

Hisense TV integration depends on your TV's operating system. Follow the method that matches your TV.

## 📋 First: Find Your TV's IP Address

1. **On your TV**: Settings → Network → Network Status
2. **On your router**: Check connected devices
3. **From terminal** (on your server):
   ```bash
   # Find TV on network
   nmap -sn 192.168.1.0/24 | grep -i hisense
   # Or check router/network admin panel
   ```

**Important**: Assign a static IP to your TV in your router settings so it doesn't change.

---

## Method 1: Android TV / Google TV Integration (If Your TV Runs Android/Google TV)

This is the **easiest method** if your Hisense TV runs Android TV or Google TV.

### Steps:

1. **Enable Developer Options** on your TV:
   - Go to Settings → About
   - Scroll to "Build" and click it 7 times
   - Enable "ADB debugging" or "Network debugging"

2. **In Home Assistant**:
   - Go to **Settings → Devices & Services**
   - Click **Add Integration** (bottom right)
   - Search for **"Android TV"**
   - Enter your TV's IP address
   - Follow the prompts

3. **Alternative**: Try **"Google Cast"** integration if your TV supports Chromecast

---

## Method 2: Vidaa OS (Using HACS Custom Integration)

If your TV runs Vidaa OS (most Hisense smart TVs), use a custom integration.

### Step 1: Install HACS (Home Assistant Community Store)

1. In Home Assistant, go to **Settings → Add-ons**
2. Install **Terminal & SSH** add-on (or use File Editor)
3. Open terminal in Home Assistant
4. Run:
   ```bash
   wget -O - https://get.hacs.xyz | bash -
   ```
5. Restart Home Assistant

### Step 2: Install Hisense TV Integration via HACS

1. Go to **HACS** → **Integrations**
2. Click **Explore & Download Repositories**
3. Search for **"Hisense TV"** or **"ha_hisense_tv"**
4. Click **Download**
5. Restart Home Assistant

### Step 3: Add the Integration

1. Go to **Settings → Devices & Services**
2. Click **Add Integration**
3. Search for **"Hisense TV"**
4. Enter your TV's IP address
5. A PIN will appear on your TV screen
6. Enter the PIN in Home Assistant

---

## Method 3: Using Python hisensetv Library (Command Line)

For Vidaa OS TVs, you can use the `hisensetv` library directly.

### Step 1: Install Library

```bash
# On your Home Assistant server
pip3 install hisensetv
```

### Step 2: Authorize the TV

```bash
# Replace with your TV's IP
hisensetv 192.168.1.XXX --authorize

# Your TV will display a PIN
# Enter the PIN when prompted
```

### Step 3: Test Connection

```bash
# Test power control
hisensetv 192.168.1.XXX --key power

# Get volume
hisensetv 192.168.1.XXX --get volume

# Set volume (0-100)
hisensetv 192.168.1.XXX --set volume 50
```

### Step 4: Add to Home Assistant via YAML

1. Edit `configuration.yaml`:
   ```yaml
   media_player:
     - platform: hisense_tv
       host: 192.168.1.XXX  # Your TV's IP
       name: "Living Room TV"
       ssl: true            # Try false if it doesn't work
   ```

2. Restart Home Assistant

---

## Method 4: Wake-on-LAN + HTTP Control (If Supported)

Some Hisense TVs can be controlled via HTTP commands.

### Check if Your TV Supports HTTP:

```bash
# Try accessing TV's web interface
curl http://192.168.1.XXX:8080/remoteControl?command=KEY_POWER

# Or check for common Hisense ports
nmap -p 36669,8080,55000 192.168.1.XXX
```

### Add Wake-on-LAN (for power on):

1. In Home Assistant: **Settings → Devices & Services**
2. Add **Wake on LAN** integration
3. Enter your TV's MAC address

### Use HTTP/REST Command Platform:

```yaml
# In configuration.yaml
media_player:
  - platform: rest
    name: "Hisense TV"
    resource: "http://192.168.1.XXX:8080/remoteControl"
    # Add commands based on your TV's API
```

---

## Method 5: HDMI-CEC (If Connected via HDMI)

If you have a device connected via HDMI (like a Raspberry Pi), you can control the TV via HDMI-CEC.

1. Install `cec-client`:
   ```bash
   sudo apt install cec-utils
   ```

2. Test:
   ```bash
   echo "on 0" | cec-client -s -d 1
   echo "standby 0" | cec-client -s -d 1
   ```

3. Add to Home Assistant via **HDMI-CEC** integration

---

## Troubleshooting

### TV Won't Connect

1. **Check Network**:
   ```bash
   ping 192.168.1.XXX  # TV IP
   ```

2. **Check TV Settings**:
   - Enable "Network Control" or "Remote Control"
   - Enable "Fast Power On" (keeps TV in standby)
   - Disable firewall on TV if present

3. **Check Ports**:
   ```bash
   nmap -p 36669,8080,55000 192.168.1.XXX
   ```

### PIN Not Appearing

- Make sure TV and Home Assistant are on the same network
- Try disabling SSL: `--no-ssl` flag in hisensetv
- Check TV firmware version (newer firmware may have restrictions)

### Power Control Not Working

- Use Wake-on-LAN for power on
- Use HDMI-CEC if available
- Some Vidaa models require TV to be in "Fast Power On" mode

---

## Which Method Should I Use?

**Check your TV model and OS:**

1. **Android TV / Google TV** → Use Method 1 (Built-in Android TV integration)
2. **Vidaa OS** → Use Method 2 (HACS custom integration)
3. **Older Smart TV** → Try Method 3 (Python library) or Method 4 (HTTP)
4. **Simple control** → Use Method 5 (HDMI-CEC)

---

## Useful Commands

```bash
# Find TV IP
arp -a | grep -i hisense

# Test connection
ping 192.168.1.XXX

# Check open ports
nmap -p 1-10000 192.168.1.XXX
```

---

## References

- Hisense TV Python library: https://github.com/newAM/hisensetv
- HA Hisense TV Integration: https://github.com/sehaas/ha_hisense_tv
- Home Assistant Android TV: https://www.home-assistant.io/integrations/androidtv/

