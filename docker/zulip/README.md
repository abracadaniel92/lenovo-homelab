# Zulip Setup & Configuration

Self-hosted team communication platform with excellent webhook support. Zulip combines real-time chat with threaded conversations organized by topics.

## 🚀 Quick Start

```bash
cd ~/Desktop/Cursor\ projects/Pi-version-control/docker/zulip
docker compose up -d
```

**Wait 2-3 minutes** for Zulip to fully initialize (it needs to set up database, run migrations, etc.)

## 📍 Access URLs

- **Local**: `http://localhost:8070`
- **Network (Direct IP)**: `http://192.168.1.97:8070`
- **Network (Domain)**: `http://zulip.gmojsoski.com:8080` (via Caddy, requires DNS)
- **External HTTPS**: `https://zulip.gmojsoski.com` (via Cloudflare Tunnel)

## 🔧 Configuration

### Initial Setup

On first access, Zulip will show a setup wizard:
1. Create your organization (e.g., "Goce's Lab")
2. Create admin account
3. Configure email (optional - can skip for now)

### Environment Variables

Key configuration in `docker-compose.yml`:
- `SETTING_EXTERNAL_HOST`: `zulip.gmojsoski.com` - Your domain
- `SETTING_ZULIP_ADMINISTRATOR`: `admin@zulip.gmojsoski.com` - Admin email
- `SECRET_KEY`: **CHANGE THIS** in production! Generate with: `openssl rand -hex 32`
- `SETTING_EMAIL_BACKEND`: `console.EmailBackend` - Disables email sending (logs to console)
- `SETTING_ZULIP_ORG_NAME`: Organization name
- `SETTING_ZULIP_ORG_SUBDOMAIN`: Subdomain for organization

### Webhooks

Zulip has excellent webhook support:
1. **Access webhook settings**: Admin panel → Integrations → Webhooks
2. **Incoming webhooks**: Create bots for incoming webhooks
3. **Outgoing webhooks**: Configure outgoing webhooks for integrations
4. **API**: Full REST API available at `/api/v1/`

**Webhook URL format**: `https://zulip.gmojsoski.com/api/v1/external/...`

## 🗄️ Database & Dependencies

Zulip uses:
- **PostgreSQL 15** - Main database (no AVX requirement! ✅)
- **Redis** - Caching and real-time features
- **RabbitMQ** - Message queue
- **Memcached** - Additional caching

All services are containerized and managed via docker-compose.

## 📝 Management Commands

```bash
# Using Makefile (from project root)
make lab-zulip-start      # Start Zulip
make lab-zulip-stop       # Stop Zulip
make lab-zulip-restart    # Restart Zulip
make lab-zulip-logs       # View logs
make lab-zulip-status     # Check status

# Or directly with docker compose
cd docker/zulip
docker compose up -d      # Start
docker compose down       # Stop
docker compose restart    # Restart
docker compose logs -f    # View logs
docker compose ps         # Check status
```

## 🔍 Troubleshooting

### Zulip not starting / taking too long
- **First startup takes 2-5 minutes** - Zulip needs to initialize database, run migrations, etc.
- Check logs: `docker compose logs zulip -f`
- Wait for "Zulip is ready!" message in logs

### Database connection errors
- Verify PostgreSQL is running: `docker compose ps zulip-postgres`
- Check PostgreSQL logs: `docker compose logs zulip-postgres`
- Ensure database container is healthy before starting Zulip (depends_on should handle this)

### Webhook not working
- Ensure `SETTING_EXTERNAL_HOST` matches your actual domain
- Check Caddy is routing correctly: `curl -H "Host: zulip.gmojsoski.com" http://localhost:8080`
- Verify SSL certificate is valid: `curl -I https://zulip.gmojsoski.com`

### Email not working
- Default setup uses `console.EmailBackend` (logs to console)
- To enable email, change `SETTING_EMAIL_BACKEND` and configure SMTP settings
- Check email settings in Admin panel → Settings → Email

## 🔐 Security Notes

1. **Change default passwords**:
   - `SECRET_KEY` in docker-compose.yml (generate with `openssl rand -hex 32`)
   - Database password (`POSTGRES_PASSWORD`)
   - RabbitMQ password (`RABBITMQ_DEFAULT_PASS`)

2. **Initial setup**: First access should be secure (create admin account)

3. **Webhooks**: Use secure webhook tokens, don't share URLs publicly

## 📚 Documentation

- **Official Docs**: https://zulip.com/help/
- **API Docs**: https://zulip.com/api/
- **Webhook Docs**: https://zulip.com/api/incoming-webhooks
- **Docker Setup**: https://zulip.readthedocs.io/en/latest/production/install/docker.html

## ✨ Features

- ✅ Real-time chat with threading
- ✅ Topic-based organization
- ✅ Excellent webhook support (incoming & outgoing)
- ✅ Full REST API
- ✅ Mobile apps (iOS, Android)
- ✅ File sharing
- ✅ Video calls (with Jitsi integration)
- ✅ Integrations (GitHub, GitLab, Jira, etc.)
- ✅ Search and filters
- ✅ Custom emoji support

