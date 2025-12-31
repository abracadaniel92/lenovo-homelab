# Jellyfin Mobile App Fix - Empty Screen

## Problem
Jellyfin works fine on web but shows empty screen on mobile app.

## Solution

### Step 1: Configure Server URL in Mobile App

1. **Open Jellyfin mobile app**
2. **Go to Settings** (gear icon)
3. **Tap "Add Server"** or edit existing server
4. **Enter Server URL**: `https://jellyfin.gmojsoski.com`
5. **Save**

**Important**: Use `https://` (not `http://`) and include the full domain.

### Step 2: Configure Base URL in Jellyfin Web Settings

1. **Open Jellyfin web interface**: https://jellyfin.gmojsoski.com
2. **Login as admin**
3. **Go to Dashboard** → **Network**
4. **Set "Base URL"** to: `/` (or leave empty)
5. **Enable "Allow remote connections to this server"**
6. **Save**

### Step 3: Verify Network Configuration

In Jellyfin Dashboard → Network:
- ✅ **Base URL**: `/` (or empty)
- ✅ **Known proxies**: Leave empty (Caddy handles this)
- ✅ **Enable HTTPS**: Should be checked (handled by Cloudflare)
- ✅ **Allow remote connections**: Enabled

### Step 4: Test Connection

1. **In mobile app**, try connecting again
2. **If still empty screen**, try:
   - Force close the app
   - Clear app cache (Android: Settings → Apps → Jellyfin → Storage → Clear Cache)
   - Reopen and reconnect

## Alternative: Direct IP Access (For Testing)

If the domain doesn't work, you can try direct IP access:

1. **Find your server's local IP**:
   ```bash
   hostname -I
   ```

2. **In mobile app**, add server: `http://YOUR_IP:8096`
   - This only works on the same network
   - Use this to test if the issue is domain-related

## Common Issues

### Issue 1: App Shows "Server Unreachable"

**Cause**: Wrong URL or network issue  
**Fix**: 
- Verify URL is exactly: `https://jellyfin.gmojsoski.com`
- Check you're on a network that can reach the server
- Try on WiFi first (not mobile data)

### Issue 2: App Connects But Shows Empty Screen

**Cause**: Base URL misconfiguration or app cache  
**Fix**:
1. Check Jellyfin web settings (Base URL should be `/` or empty)
2. Clear mobile app cache
3. Remove and re-add server in mobile app

### Issue 3: SSL Certificate Error

**Cause**: App doesn't trust Cloudflare's certificate  
**Fix**: 
- This shouldn't happen with Cloudflare, but if it does:
- In mobile app settings, look for "Accept invalid certificates" or similar
- Enable it temporarily to test

## Verification

After configuration, verify:

1. **Web access works**: https://jellyfin.gmojsoski.com
2. **Mobile app can connect**: Shows server in app
3. **Content loads**: Libraries appear in mobile app

## Quick Test Commands

```bash
# Test Jellyfin direct access
curl -I http://localhost:8096

# Test via Caddy
curl -I -H "Host: jellyfin.gmojsoski.com" http://localhost:8080

# Test external HTTPS
curl -I https://jellyfin.gmojsoski.com
```

All should return `200` or `302` status codes.

## iOS-Specific Fixes (Error -999)

If you see `NSURLErrorDomain Code=-999 "cancelled"` on iOS:

### Fix 1: Force Close and Reconnect
1. **Force close the Jellyfin app** (swipe up from app switcher)
2. **Reopen the app**
3. **Remove and re-add the server**:
   - Settings → Servers → Remove existing server
   - Add Server: `https://jellyfin.gmojsoski.com`
   - Save and connect

### Fix 2: Check Jellyfin Network Settings
1. Open https://jellyfin.gmojsoski.com in browser
2. Login as admin
3. **Dashboard → Network**:
   - Base URL: `/` (or empty)
   - Enable "Allow remote connections to this server"
   - Save

### Fix 3: WebSocket Support (Already Configured)
The Caddy configuration now includes:
- WebSocket support
- Increased timeout (300 seconds)
- Proper headers for mobile apps

### Fix 4: Clear App Data (Last Resort)
- **iOS**: Delete and reinstall the app
- **Android**: Settings → Apps → Jellyfin → Storage → Clear Data

## Still Not Working?

1. **Check Jellyfin logs**:
   ```bash
   docker logs jellyfin --tail 50
   ```

2. **Check Caddy logs**:
   ```bash
   docker logs caddy --tail 50
   ```

3. **Restart Jellyfin**:
   ```bash
   docker restart jellyfin
   ```

4. **Restart Caddy**:
   ```bash
   docker restart caddy
   ```

5. **Test WebSocket connection**:
   ```bash
   curl -H "Host: jellyfin.gmojsoski.com" -H "Upgrade: websocket" -H "Connection: Upgrade" http://localhost:8080/
   ```

