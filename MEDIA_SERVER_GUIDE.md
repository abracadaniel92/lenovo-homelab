# Media Server Setup Guide

## Overview

Media servers allow you to stream your music, videos, and photos to any device, including your iPhone.

## How It Works

### iPhone Access
- ✅ **Works great with iPhone** - Native apps available
- ✅ **No Bluetooth needed** - Streams over WiFi/cellular network
- ✅ **Access from anywhere** - Home network or remotely via Cloudflare tunnel

### Bluetooth vs Network Streaming

**Bluetooth:**
- Only needed for direct iPhone → Bluetooth speaker connection
- Limited range (~10 meters)
- Lower quality audio
- One device at a time

**Network Streaming (Media Server):**
- Streams over WiFi/cellular network
- Better quality (no compression)
- Can stream to multiple devices
- Works with AirPlay, Chromecast, network speakers
- Access from anywhere

## Popular Media Server Options

### 1. Jellyfin (Recommended - Free & Open Source)
- ✅ Completely free
- ✅ Open source
- ✅ No account required
- ✅ Great iPhone app
- ✅ Supports music, videos, photos, live TV
- ✅ Can cast to AirPlay/Chromecast devices

### 2. Plex
- ✅ Free tier available
- ⚠️ Requires account (can use local account)
- ✅ Excellent iPhone app
- ✅ Great user interface
- ⚠️ Some features require Plex Pass (paid)

### 3. Emby
- ✅ Free tier available
- ⚠️ Some features require Emby Premiere (paid)
- ✅ Good iPhone app
- ✅ Similar to Plex

## Recommended Setup: Jellyfin

### Why Jellyfin?
- Completely free and open source
- No account required
- Full feature set without paywall
- Great community support
- Can be accessed via Cloudflare tunnel (like your other services)

### Installation

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
      - /path/to/media:/media  # Your music/videos/photos
    environment:
      - PUID=1000
      - PGID=1000
```

### iPhone App
1. Install "Jellyfin" from App Store
2. Open app
3. Add server: `https://jellyfin.gmojsoski.com` (or your domain)
4. Login and start streaming!

## Wireless Speaker Options

### Option 1: Bluetooth (Direct iPhone → Speaker)
- ✅ Simple setup
- ✅ Works with any Bluetooth speaker
- ⚠️ Requires Bluetooth enabled on iPhone
- ⚠️ Limited range
- ⚠️ Lower quality

### Option 2: AirPlay (iPhone → AirPlay Speaker)
- ✅ Better quality than Bluetooth
- ✅ No Bluetooth needed
- ✅ Works over WiFi
- ⚠️ Requires AirPlay-compatible speaker/device

### Option 3: Network Streaming (Media Server → Speaker)
- ✅ Best quality
- ✅ Can control from iPhone
- ✅ Works with network speakers (Sonos, etc.)
- ✅ Can cast to Chromecast/AirPlay devices
- ✅ Multiple devices can stream simultaneously

### Option 4: Cast from iPhone App
- ✅ Use Jellyfin/Plex app on iPhone
- ✅ Cast to network devices (Chromecast, AirPlay, etc.)
- ✅ No Bluetooth needed
- ✅ Better quality

## Setup Steps

1. **Install Media Server** (Jellyfin recommended)
2. **Add to Caddy** (reverse proxy)
3. **Add to Cloudflare Tunnel** (for remote access)
4. **Install iPhone app**
5. **Add media files** to server
6. **Start streaming!**

## Example: Jellyfin with Your Setup

### Caddy Configuration
```caddy
@jellyfin host jellyfin.gmojsoski.com
handle @jellyfin {
    encode gzip
    reverse_proxy http://172.17.0.1:8096 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
        header_up Host {host}
    }
}
```

### Cloudflare Tunnel
```yaml
- hostname: jellyfin.gmojsoski.com
  service: http://localhost:8080
```

## Benefits

✅ **Access from anywhere** - Home or remote
✅ **No Bluetooth needed** - Network streaming
✅ **Better quality** - No compression
✅ **Multiple devices** - Stream to phone, TV, speakers simultaneously
✅ **Organized library** - All your media in one place
✅ **Automatic metadata** - Album art, descriptions, etc.

## Summary

- **iPhone access:** ✅ Yes, works great!
- **Bluetooth needed:** ❌ No, only for direct iPhone → speaker
- **Network streaming:** ✅ Yes, better quality and range
- **Remote access:** ✅ Yes, via Cloudflare tunnel
- **Recommended:** Jellyfin (free, open source, full features)

