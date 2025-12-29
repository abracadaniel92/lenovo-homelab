# Uptime Kuma - Caddy Monitor Setup

## Caddy Monitor Configuration

1. **Open Uptime Kuma**: `http://localhost:3001`

2. **Click "Add New Monitor"**

3. **Configure**:
   - **Monitor Type**: HTTP(s)
   - **Friendly Name**: `Caddy (Local)`
   - **URL**: `http://192.168.1.97:8080`
     - (Use your host IP since Uptime Kuma is in Docker)
   - **Interval**: 60 seconds
   - **Retry Interval**: 30 seconds
   - **Max Retries**: 3
   - **Expected Status Code**: 200
   - **Headers** (optional, but recommended):
     - Key: `Host`
     - Value: `gmojsoski.com`

4. **Notify Section**:
   - Select your existing Slack notification
   - Enable: ✓ **Notify When Down**
   - Enable: ✓ **Notify When Up** (optional)

5. **Click "Save"**

## Other Services You Should Monitor

### Critical Services (Recommended)

1. **Cloudflared Tunnel** (Public)
   - URL: `https://gmojsoski.com`
   - Type: HTTP(s) - Keyword
   - Keyword: `gmojsoski`
   - **Why**: Monitors the full user experience

2. **Nextcloud**
   - URL: `https://cloud.gmojsoski.com`
   - Type: HTTP(s)
   - **Why**: Your cloud storage service

3. **GoatCounter** (Analytics)
   - URL: `https://analytics.gmojsoski.com`
   - Type: HTTP(s)
   - **Why**: Your analytics service

4. **Gokapi** (File Sharing)
   - URL: `https://files.gmojsoski.com`
   - Type: HTTP(s)
   - **Why**: Your file sharing service

### Optional Services

5. **Documents-to-Calendar**
   - URL: `https://tickets.gmojsoski.com`
   - Type: HTTP(s)

6. **Bookmarks**
   - URL: `https://bookmarks.gmojsoski.com`
   - Type: HTTP(s)

7. **Cloudflared Metrics** (Advanced)
   - URL: `http://192.168.1.97:20241/metrics`
   - Type: HTTP(s) - Keyword
   - Keyword: `cloudflared`
   - **Why**: Direct check of cloudflared process

## Quick Setup Summary

**Minimum Monitoring** (Recommended):
- ✅ Caddy (Local) - `http://192.168.1.97:8080`
- ✅ Cloudflared Tunnel (Public) - `https://gmojsoski.com`

**Full Monitoring** (All Services):
- ✅ Caddy (Local)
- ✅ Cloudflared Tunnel (Public)
- ✅ Nextcloud
- ✅ GoatCounter
- ✅ Gokapi
- ✅ Documents-to-Calendar
- ✅ Bookmarks

All monitors can use the same Slack notification!

