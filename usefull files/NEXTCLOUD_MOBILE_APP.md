# Nextcloud Mobile App Connection Guide

## Common Connection Issues

### 1. Connection Error / Cannot Connect

**Symptoms:**
- Mobile app shows "Connection error" or "Cannot connect to server"
- Login fails immediately

**Solutions:**

#### A. Verify Server URL
In the mobile app, use the **exact URL**:
```
https://cloud.gmojsoski.com
```

**Important:**
- ✅ Use `https://` (not `http://`)
- ✅ Use the full domain: `cloud.gmojsoski.com`
- ❌ Don't use `localhost` or IP address
- ❌ Don't add port numbers (like `:8081`)

#### B. Allow Untrusted Certificates (If Needed)
If you get SSL/certificate errors:

**Android:**
1. In Nextcloud app settings
2. Enable "Allow untrusted certificates" or "Accept self-signed certificates"
3. This is safe because Cloudflare provides the certificate

**iOS:**
1. iOS generally trusts Cloudflare certificates
2. If issues persist, check that the certificate chain is valid

#### C. Check Server Configuration
Ensure the server is configured correctly:

```bash
# Verify trusted domains
docker exec nextcloud-app php /var/www/html/occ config:system:get trusted_domains

# Verify overwrite settings
docker exec nextcloud-app php /var/www/html/occ config:system:get overwritehost
docker exec nextcloud-app php /var/www/html/occ config:system:get overwriteprotocol
docker exec nextcloud-app php /var/www/html/occ config:system:get overwrite.cli.url
```

Should show:
- `trusted_domains`: `localhost`, `cloud.gmojsoski.com`
- `overwritehost`: `cloud.gmojsoski.com`
- `overwriteprotocol`: `https`
- `overwrite.cli.url`: `https://cloud.gmojsoski.com`

#### D. Fix Configuration (If Needed)
```bash
# Set correct CLI URL
docker exec nextcloud-app php /var/www/html/occ config:system:set overwrite.cli.url --value=https://cloud.gmojsoski.com

# Verify server is accessible
curl -I https://cloud.gmojsoski.com
```

### 2. Login Credentials Error

**Symptoms:**
- App connects but login fails
- "Invalid credentials" error

**Solutions:**
1. **Verify username and password** - Use the exact credentials from web login
2. **Check if 2FA is enabled** - Mobile apps need app-specific passwords if 2FA is enabled
3. **Reset password** if needed:
   ```bash
   docker exec nextcloud-app php /var/www/html/occ user:password USERNAME NEW_PASSWORD
   ```

### 3. Slow Connection / Timeout

**Symptoms:**
- App takes long time to connect
- Connection times out

**Solutions:**
1. **Check network** - Ensure mobile device has internet connection
2. **Check Cloudflare tunnel** - Verify it's running:
   ```bash
   systemctl status cloudflared
   ```
3. **Check Nextcloud logs**:
   ```bash
   docker logs nextcloud-app --tail 50
   ```

### 4. App Can't Find Server

**Symptoms:**
- App says "Server not found"
- DNS resolution fails

**Solutions:**
1. **Use domain name** - Don't use IP addresses
2. **Check DNS** - Verify `cloud.gmojsoski.com` resolves correctly
3. **Try on different network** - Test on WiFi vs mobile data

## Step-by-Step Mobile App Setup

### Android / iOS

1. **Download Nextcloud app** from Play Store / App Store

2. **Add Server:**
   - Tap "Add account" or "+"
   - Enter server URL: `https://cloud.gmojsoski.com`
   - Tap "Connect"

3. **Login:**
   - Enter your username
   - Enter your password
   - Tap "Login"

4. **If certificate warning appears:**
   - Android: Enable "Allow untrusted certificates" in app settings
   - iOS: Usually not needed (Cloudflare certs are trusted)

5. **Grant Permissions:**
   - Allow access to photos/files
   - Enable background sync (optional)

## Troubleshooting Commands

```bash
# Check if server is accessible
curl -I https://cloud.gmojsoski.com

# Check Nextcloud status
curl https://cloud.gmojsoski.com/status.php

# View recent logs
docker logs nextcloud-app --tail 50

# Check trusted domains
docker exec nextcloud-app php /var/www/html/occ config:system:get trusted_domains

# Test API endpoint (used by mobile apps)
curl https://cloud.gmojsoski.com/ocs/v1.php/cloud/capabilities
```

## Current Configuration (Dec 29, 2025)

- **Server URL**: `https://cloud.gmojsoski.com`
- **Trusted Domains**: `localhost`, `cloud.gmojsoski.com`
- **Overwrite Host**: `cloud.gmojsoski.com`
- **Overwrite Protocol**: `https`
- **CLI URL**: `https://cloud.gmojsoski.com`
- **Version**: Nextcloud 30.0.17.2

## Still Having Issues?

1. **Check server logs** for specific errors
2. **Try web interface** - If web works but mobile doesn't, it's likely a mobile app configuration issue
3. **Check firewall** - Ensure Cloudflare tunnel is accessible
4. **Verify Cloudflare tunnel** is running and routing correctly

