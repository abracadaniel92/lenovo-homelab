# Bluetooth Audio Setup for Media Server

## Overview

Set up Bluetooth audio output from your Lenovo server so media server audio plays through a Bluetooth speaker.

## Flow

```
Media Server (Jellyfin) → Lenovo Server → Bluetooth Dongle → Bluetooth Speaker
```

You control playback from your iPhone app, but audio comes from the Lenovo server through the Bluetooth speaker.

## Prerequisites

1. ✅ Bluetooth dongle plugged into Lenovo
2. ✅ Bluetooth speaker (powered on, in pairing mode)
3. ✅ Media server installed (Jellyfin/Plex/Emby)

## Installation Steps

### 1. Install Bluetooth Tools

```bash
sudo apt update
sudo apt install -y bluez bluez-tools pulseaudio pulseaudio-module-bluetooth
```

### 2. Enable Bluetooth Service

```bash
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

### 3. Check Bluetooth Dongle

```bash
# Check if dongle is detected
lsusb | grep -i bluetooth

# Check Bluetooth status
bluetoothctl show
```

### 4. Pair Bluetooth Speaker

```bash
# Start Bluetooth control
bluetoothctl

# In bluetoothctl:
power on                    # Turn on Bluetooth
scan on                     # Scan for devices
# Wait for your speaker to appear, note its MAC address
pair <MAC_ADDRESS>          # Pair with speaker
trust <MAC_ADDRESS>         # Trust the device
connect <MAC_ADDRESS>       # Connect to speaker
exit                        # Exit bluetoothctl
```

### 5. Configure PulseAudio for Bluetooth

```bash
# Load Bluetooth module
pactl load-module module-bluetooth-discover

# List audio devices
pactl list short sinks

# Set Bluetooth as default output (if needed)
pactl set-default-sink <BLUETOOTH_SINK_NAME>
```

### 6. Configure Media Server Audio Output

#### For Jellyfin (Docker)

Add audio device to Docker container:

```yaml
# docker-compose.yml
services:
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    restart: always
    ports:
      - "8096:8096"
    volumes:
      - ./config:/config
      - ./cache:/cache
      - /path/to/media:/media
    devices:
      - /dev/snd:/dev/snd  # Audio devices
    environment:
      - PULSE_SERVER=unix:/run/user/1000/pulse/native
    volumes:
      - /run/user/1000/pulse:/run/user/1000/pulse:ro
```

#### Alternative: Use ALSA

If PulseAudio doesn't work in Docker, use ALSA:

```yaml
services:
  jellyfin:
    # ... other config ...
    devices:
      - /dev/snd:/dev/snd
    environment:
      - ALSA_CARD=1  # Bluetooth audio card number
```

### 7. Test Audio Output

```bash
# Test with aplay (if ALSA)
aplay /usr/share/sounds/alsa/Front_Left.wav

# Test with paplay (if PulseAudio)
paplay /usr/share/sounds/freedesktop/stereo/bell.ogg
```

## Control Playback

### From iPhone App

1. Open Jellyfin/Plex app on iPhone
2. Select media to play
3. Choose output device (if app supports it)
4. Or configure server to always use Bluetooth

### From Web Interface

1. Access media server web UI
2. Play media
3. Audio should automatically go to Bluetooth speaker

## Troubleshooting

### Bluetooth Dongle Not Detected

```bash
# Check USB devices
lsusb

# Check kernel messages
dmesg | grep -i bluetooth

# Try unplugging and replugging dongle
```

### Speaker Not Pairing

```bash
# Make sure speaker is in pairing mode
# Remove old pairing and try again
bluetoothctl
remove <MAC_ADDRESS>
scan on
pair <MAC_ADDRESS>
```

### Audio Not Playing

```bash
# Check if Bluetooth is connected
bluetoothctl devices Connected

# Check audio sinks
pactl list short sinks

# Check if PulseAudio sees Bluetooth
pactl list modules | grep bluetooth

# Restart PulseAudio
pulseaudio -k
pulseaudio --start
```

### Docker Container Can't Access Audio

```bash
# Make sure user is in audio group
sudo usermod -aG audio $USER

# Check audio group
groups

# Restart Docker container after adding to audio group
```

## Auto-Connect Bluetooth Speaker

Create a script to auto-connect on boot:

```bash
#!/bin/bash
# /usr/local/bin/auto-connect-bluetooth.sh

SPEAKER_MAC="XX:XX:XX:XX:XX:XX"  # Your speaker MAC address

bluetoothctl power on
sleep 2
bluetoothctl connect $SPEAKER_MAC
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/auto-connect-bluetooth.sh
```

Add to systemd service or cron for auto-connect on boot.

## Alternative: Use Network Audio

If Bluetooth is problematic, consider:
- **AirPlay receiver** on Lenovo (shairport-sync)
- **DLNA/UPnP** streaming to network speakers
- **Chromecast Audio** (if available)

## Summary

✅ **Bluetooth dongle** → Plug into Lenovo
✅ **Install Bluetooth tools** → bluez, pulseaudio
✅ **Pair speaker** → bluetoothctl
✅ **Configure audio** → PulseAudio/ALSA
✅ **Configure media server** → Use Bluetooth audio output
✅ **Control from iPhone** → Play from app, audio from server

The media server will output audio through the Lenovo's Bluetooth to your speaker!

