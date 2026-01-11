# Mattermost Setup & Configuration

Self-hosted team communication platform - open-source Slack alternative. Mattermost provides real-time messaging, file sharing, and webhooks.

## 🚀 Quick Start

```bash
cd ~/Desktop/Cursor\ projects/Pi-version-control/docker/mattermost
docker compose up -d
```

**Wait 1-2 minutes** for Mattermost to fully initialize (it needs to set up database, run migrations, etc.)

## 📍 Access URLs

- **Local**: `http://localhost:8066`
- **Network (Direct IP)**: `http://192.168.1.97:8066`
- **External HTTPS**: `https://mattermost.gmojsoski.com` (via Cloudflare Tunnel)

**Important**: All devices (WiFi and mobile) should access via `https://mattermost.gmojsoski.com`. Do NOT add a Pi-hole Local DNS Record for this domain - it will cause the same WiFi access issues that were fixed for other services.

## 🔧 Configuration

### Initial Setup

On first access, Mattermost will show a setup wizard:
1. Create your first team (e.g., "Main Team")
2. Create admin account
3. Configure email (optional - can use console backend for now)

### Environment Variables

Key configuration in `docker-compose.yml`:
- `MM_SERVICESETTINGS_SITEURL`: `https://mattermost.gmojsoski.com` - Your domain
- `MM_SERVICESETTINGS_ENABLEOPENSERVER`: `true` - Allows user sign-up
- `MM_EMAILSETTINGS_ENABLESIGNUPWITHEMAIL`: `true` - Enable email signup
- `MM_EMAILSETTINGS_ENABLESIGNINWITHEMAIL`: `true` - Enable email signin
- `MM_EMAILSETTINGS_SENDPUSHNOTIFICATIONS`: `true` - Enable mobile push notifications
- `MM_EMAILSETTINGS_PUSHNOTIFICATIONSERVER`: `https://push-test.mattermost.com` - TPNS server (free for non-commercial)
- Database credentials: `mmuser` / `mmuser_password` (**CHANGE IN PRODUCTION!**)

### Webhooks & Integrations

Mattermost has excellent webhook support:
1. **Incoming Webhooks**: System Console → Integrations → Incoming Webhooks
2. **Outgoing Webhooks**: System Console → Integrations → Outgoing Webhooks
3. **Slash Commands**: System Console → Integrations → Slash Commands
4. **REST API**: Full REST API available at `/api/v4/`

**Webhook URL format**: `https://mattermost.gmojsoski.com/hooks/...`

**Custom Bot Usernames:**
To allow webhooks to use custom usernames (like "System Bot" instead of your username):
1. Go to **System Console** → **Integrations**
2. Enable **"Enable integrations to override usernames"** (`EnablePostUsernameOverride`)
3. Enable **"Enable integrations to override profile picture icons"** (`EnablePostIconOverride`)
4. Save the changes

After enabling these settings, webhooks can use the `username` field in their payloads to customize the display name.

### Plugins

Mattermost supports plugins for extending functionality. To install plugins:

1. **Via Web UI (Recommended)**:
   - Go to System Console → Plugins → Plugin Management
   - Click "Upload Plugin" or "Choose File"
   - Select the plugin `.tar.gz` file
   - Click "Upload" and wait for the plugin to be extracted
   - Find the plugin in the list and toggle it to "Enabled"

2. **RSS Feed Plugin**:
   - **Download**: Pre-built releases available at https://github.com/wbernest/mattermost-plugin-rssfeed/releases
   - **Usage**: After installation and enabling, use `/feed` slash commands in channels to subscribe to RSS feeds
   - **Commands**:
     - `/feed subscribe [RSS Feed URL]` - Subscribe to an RSS feed in the current channel
     - `/feed list` - List all RSS feeds the current channel is subscribed to
     - `/feed unsubscribe [RSS Feed URL]` - Unsubscribe from a specific RSS feed
   - **Configuration**: In System Console → Plugins → RSSFeed, configure:
     - Time window between RSS feed checks (minutes)
     - Show Description in RSS post
   - **Integration Settings**: In System Console → Integration Management, enable:
     - Enable integrations to override usernames
     - Enable integrations to override profile picture icons
   - **Documentation**: https://github.com/wbernest/mattermost-plugin-rssfeed

## 🗄️ Database & Dependencies

Mattermost uses:
- **PostgreSQL 15** - Main database (no AVX requirement! ✅)
- **File storage** - Local volumes for uploads and files
- **Bleve** - Full-text search indexing

All services are containerized and managed via docker-compose.

## 📝 Management Commands

```bash
# Using Makefile (from project root)
make lab-mattermost-start      # Start Mattermost
make lab-mattermost-stop       # Stop Mattermost
make lab-mattermost-restart    # Restart Mattermost
make lab-mattermost-logs       # View logs
make lab-mattermost-status     # Check status

# Or directly with docker compose
cd docker/mattermost
docker compose up -d      # Start
docker compose down       # Stop
docker compose restart    # Restart
docker compose logs -f    # View logs
docker compose ps         # Check status
```

## 🔍 Troubleshooting

### Mattermost not starting / taking too long
- **First startup takes 1-3 minutes** - Mattermost needs to initialize database, run migrations, etc.
- Check logs: `docker compose logs mattermost -f`
- Wait for "Server is listening on :8065" message in logs
- Check database is healthy: `docker compose ps mattermost-postgres`

### Database connection errors
- Verify PostgreSQL is running: `docker compose ps mattermost-postgres`
- Check PostgreSQL logs: `docker compose logs mattermost-postgres`
- Ensure database container is healthy before starting Mattermost (depends_on should handle this)
- Check credentials match in both services

### Can't access web interface
- **External HTTPS**: Use `https://mattermost.gmojsoski.com` (via Cloudflare Tunnel)
- **Local**: Use `http://localhost:8066` (direct access)
- Verify Caddy is routing correctly: `curl -H "Host: mattermost.gmojsoski.com" http://localhost:8080`
- Check Cloudflare Tunnel config has `mattermost.gmojsoski.com` entry

### WiFi access issues (should NOT happen now)
- **DO NOT** add Pi-hole Local DNS Record for `mattermost.gmojsoski.com`
- All devices (WiFi and mobile) should use Cloudflare DNS
- If WiFi access fails, it's likely the same DNS issue that was fixed for other services
- Solution: Remove any Pi-hole Local DNS Record for `mattermost.gmojsoski.com`

### Webhook not working
- Ensure `MM_SERVICESETTINGS_SITEURL` matches your actual domain (`https://mattermost.gmojsoski.com`)
- Check Caddy is routing correctly: `curl -H "Host: mattermost.gmojsoski.com" http://localhost:8080`
- Verify webhook URL in Mattermost admin panel
- Check Mattermost logs for webhook errors: `docker compose logs mattermost | grep -i webhook`

### Email not working
- Default setup allows email signup/signin but doesn't send emails
- To enable email sending, configure SMTP settings in System Console → Email
- For development, you can keep the console backend

### Mobile push notifications not working
- Push notifications are enabled via TPNS (Test Push Notification Service)
- TPNS is free for non-commercial self-hosted installations
- **Note**: TPNS doesn't have production-level SLAs (not recommended for production)
- For production use, consider upgrading to Enterprise/Professional for HPNS (Hosted Push Notification Service)
- Ensure `MM_EMAILSETTINGS_SENDPUSHNOTIFICATIONS` is set to `"true"` in docker-compose.yml
- Ensure `MM_EMAILSETTINGS_PUSHNOTIFICATIONSERVER` points to the correct server
- After changing push notification settings, restart Mattermost: `docker compose restart mattermost`
- Users need to enable push notifications in their mobile app settings (Settings → Notifications)

## 🔐 Security Notes

1. **Change default passwords**:
   - Database password (`POSTGRES_PASSWORD` in docker-compose.yml)
   - Admin password (set during first-time setup)
   - Generate secure password: `openssl rand -base64 32`

2. **Initial setup**: First access should be secure (create admin account)

3. **Webhooks**: Use secure webhook tokens, don't share URLs publicly

4. **File uploads**: Default max file size is 50MB (configurable via `MM_FILESETTINGS_MAXFILESIZE`)

## 📚 Documentation

- **Official Docs**: https://docs.mattermost.com/
- **API Docs**: https://api.mattermost.com/
- **Webhook Docs**: https://developers.mattermost.com/integrate/webhooks/incoming/
- **Docker Setup**: https://docs.mattermost.com/install/docker-local-machine.html

## ✨ Features

- ✅ Real-time messaging (channels and direct messages)
- ✅ File sharing and attachments
- ✅ Webhooks (incoming & outgoing)
- ✅ Slash commands
- ✅ Full REST API
- ✅ Mobile apps (iOS, Android)
- ✅ Video calls (with Jitsi integration)
- ✅ Integrations (GitHub, GitLab, Jenkins, etc.)
- ✅ Search and filters
- ✅ Custom emoji support
- ✅ Threads and reactions

## ⚠️ Important Configuration Notes

### DNS Configuration (CRITICAL - Do NOT Add Pi-hole Local DNS Record)
- **DO NOT** add `mattermost.gmojsoski.com` to Pi-hole Local DNS Records
- All devices (WiFi and mobile) should use Cloudflare DNS
- This ensures consistent access through Cloudflare Tunnel
- Previous WiFi access issues were caused by Pi-hole Local DNS Records resolving to local IP

### Caddy Configuration
- Mattermost is configured in Caddyfile with:
  - **NO gzip encoding** - Can cause issues with real-time features and webhooks
  - Proper headers: `X-Forwarded-Proto`, `X-Forwarded-Ssl`, `Host`
  - Reverse proxy to `http://172.17.0.1:8066` (host port mapping)

### Cloudflare Tunnel Configuration
- Mattermost is configured in `~/.cloudflared/config.yml`
- Routes `mattermost.gmojsoski.com` → `http://localhost:8080` (Caddy)
- All SSL termination handled by Cloudflare

## 🔄 Migration from Previous Setup

If you had Mattermost installed before:
1. **Old configuration** used port 8065 directly
2. **New configuration** uses port 8066 (host) → 8065 (container) to avoid conflict with RocketChat
3. **No Pi-hole Local DNS Record** - This was the root cause of previous WiFi access issues
4. **All access via Cloudflare Tunnel** - Consistent behavior across all networks

## 🐛 Known Issues & Solutions

### Issue: Intermittent 530/502 errors
**Solution**: This was caused by Pi-hole Local DNS Records. Ensure no Local DNS Record exists for `mattermost.gmojsoski.com`. All devices should use Cloudflare DNS.

### Issue: Health check failures
**Solution**: Health checks verify external HTTPS access. If DNS is misconfigured (Pi-hole Local DNS Record), health checks will fail intermittently.

### Issue: Webhooks returning 530 errors
**Possible causes**:
- Rate limiting on external services (e.g., ntfy.sh)
- DNS resolution issues from container
- Network connectivity problems

**Solutions**:
- Check Mattermost container can reach external services: `docker exec mattermost curl -I https://ntfy.sh`
- Verify webhook URL is correct
- Check Mattermost logs for specific errors
