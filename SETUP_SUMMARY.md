# Quick Setup Summary

This document provides a quick reference for setting up this Lenovo ThinkCentre configuration.

## Files Included

### Docker Services
- ✅ **Caddy** - Reverse proxy (`docker/caddy/`)
- ✅ **GoatCounter** - Analytics (`docker/goatcounter/`)
- ✅ **Nextcloud** - Cloud storage (`docker/nextcloud/`)
- ✅ **Uptime Kuma** - Monitoring (`docker/uptime-kuma/`)
- ✅ **Documents-to-Calendar** - Document processing (`docker/documents-to-calendar/`)
- ✅ **Pi-hole** - DNS/Ad blocking (`docker/pihole/`)
- ✅ **Portainer** - Docker management UI (`docker/portainer/`)
- ✅ **Homepage** - Service dashboard (`scripts/install-homepage.sh`)
- ✅ **Watchtower** - Auto-update containers (`scripts/install-watchtower.sh`)
- ✅ **FileBrowser** - Web file manager (`scripts/install-filebrowser.sh`)

### System Services
- ✅ **Gokapi** - File sharing (`gokapi/`, `systemd/gokapi.service`)
- ✅ **Cloudflare Tunnel** - Secure tunnel (`cloudflare/config.yml`, `systemd/cloudflared.service`)
- ✅ **Bookmarks** - Slack bookmarks Flask service (`systemd/bookmarks.service`)
- ✅ **Planning Poker** - Planning poker web app (`systemd/planning-poker.service`)

## Quick Start Checklist

1. [ ] Install Docker and Docker Compose
2. [ ] Mount SSD to `/mnt/ssd` (optional but recommended)
3. [ ] Create directory structure
4. [ ] Setup Caddy reverse proxy
5. [ ] Setup Cloudflare Tunnel
6. [ ] Setup Gokapi
7. [ ] Deploy Docker services
8. [ ] Configure domain DNS
9. [ ] Update all passwords and secrets
10. [ ] Test all services

## Important Notes

- **Passwords**: All default passwords must be changed before production use
- **Credentials**: Cloudflare tunnel credentials file must be obtained from Cloudflare dashboard
- **Gokapi**: Use `config.json.template` and generate your own salts
- **Environment Variables**: Create `.env` files for services that need them (Documents-to-Calendar)

## Service Ports

| Service | Port | Domain |
|---------|------|--------|
| Caddy HTTP | 8080 | - |
| Caddy HTTPS | 8443 | - |
| GoatCounter | 8088 | analytics.gmojsoski.com |
| Gokapi | 8091 | files.gmojsoski.com |
| Nextcloud | 8081 | cloud.gmojsoski.com |
| Uptime Kuma | 3001 | - |
| Documents-to-Calendar | 8000 | tickets.gmojsoski.com |
| Bookmarks | 5000 | bookmarks.gmojsoski.com |
| Planning Poker | 3000 | poker.gmojsoski.com |
| Homepage | 3002 | - |
| FileBrowser | 8082 | - |
| Portainer | 9000/9443 | - |
| Pi-hole DNS | 53 | - |

## Next Steps

See the main [README.md](README.md) for detailed setup instructions.

