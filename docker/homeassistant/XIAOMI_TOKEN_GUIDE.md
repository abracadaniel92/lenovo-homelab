# Getting Xiaomi Device Tokens for Home Assistant

Xiaomi devices require a token to control them locally. Here's how to get it.

## Method 1: Extract from Xiaomi Home App (Android) - Easiest

### Option A: Using Mi Home App Database
1. **Enable Developer Options** on your Android device:
   - Settings → About Phone → Tap "Build Number" 7 times
   
2. **Enable USB Debugging**:
   - Settings → Developer Options → USB Debugging

3. **Connect phone to your computer** via USB

4. **Install ADB** (if not installed):
   ```bash
   sudo apt install adb
   ```

5. **Extract tokens**:
   ```bash
   # Connect to phone
   adb shell
   
   # Navigate to Mi Home database
   cd /data/data/com.xiaomi.smarthome/databases
   
   # Copy database to accessible location
   cp miio2.db /sdcard/
   
   # Exit adb shell
   exit
   
   # Pull database file
   adb pull /sdcard/miio2.db ~/
   
   # View database (install sqlite3 if needed)
   sudo apt install sqlite3
   sqlite3 ~/miio2.db
   
   # Query tokens
   .mode column
   .headers on
   SELECT name, localip, token FROM devicerecord;
   ```

### Option B: Using Token Extractor App
1. Download **Mi Home Token Extractor** from GitHub:
   - https://github.com/Maxmudjon/com.xiaomi-miio.extractor

2. Install on Android device and follow the app instructions

## Method 2: Using Python Script (Alternative)

1. **Install required packages**:
   ```bash
   pip3 install python-miio
   ```

2. **Use miio discovery tool**:
   ```bash
   python3 -m miio.discovery
   # Wait for devices to appear, note their IP and token
   ```

3. **Or use mirobo tool** (if you have robot vacuum):
   ```bash
   pip3 install mirobo
   mirobo --discover
   ```

## Method 3: Using miio2.db on Android (Simplified)

If you have root access or can access the Mi Home app database:

1. **On Android device**, if you have a file manager with root access:
   - Navigate to: `/data/data/com.xiaomi.smarthome/databases/miio2.db`
   - Copy to SD card
   - Transfer to computer

2. **Open database**:
   ```bash
   sqlite3 miio2.db
   SELECT name, localip, token FROM devicerecord;
   ```

## Method 4: Check Home Assistant Logs

Sometimes Home Assistant shows partial token info in logs:

```bash
cd /home/docker-projects/homeassistant
docker compose logs | grep -i xiaomi
docker compose logs | grep -i token
```

## Adding Token to Home Assistant

Once you have the token:

1. **Go to Home Assistant**: Settings → Devices & Services
2. **Find your Xiaomi integration**
3. **Click Configure** on the device
4. **Enter the token** in the configuration

Or if using YAML configuration:

```yaml
# In configuration.yaml
xiaomi_miio:
  - host: 192.168.1.XXX
    token: YOUR_TOKEN_HERE
    name: Device Name
```

## Alternative: Use Xiaomi Gateway

If you have a Xiaomi Gateway (Aqara Hub), you can:
1. Add the gateway to Home Assistant
2. Devices connected to the gateway will be available automatically
3. This requires gateway token instead of individual device tokens

## Troubleshooting

- **Token is 32 characters**: Should look like `0123456789abcdef0123456789abcdef`
- **Token format**: Hexadecimal string (0-9, a-f)
- **Invalid token**: Try extracting again or reset device
- **Device reset**: If device is reset, token changes and needs to be extracted again

## Useful Links

- Home Assistant Xiaomi Integration: https://www.home-assistant.io/integrations/xiaomi_miio/
- Token Extractor: https://github.com/Maxmudjon/com.xiaomi-miio.extractor
- Python-miio library: https://github.com/rytilahti/python-miio

