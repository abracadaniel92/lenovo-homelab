# Lenovo ThinkCentre Configuration & Setup

[![GitHub last commit](https://img.shields.io/github/last-commit/abracadaniel92/lenovo-homelab?style=flat-square&logo=github)](https://github.com/abracadaniel92/lenovo-homelab/commits/main)
[![Docker](https://img.shields.io/badge/containers-17-blue?style=flat-square&logo=docker)](https://github.com/abracadaniel92/lenovo-homelab)


This repository contains all configuration files, scripts, and setup instructions for a self-hosted home server. The server runs multiple services including Docker containers, reverse proxy (Caddy), Cloudflare Tunnel, and various applications.

## 📋 Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Running Services](#running-services)
- [Directory Structure](#directory-structure)
- [Setup Instructions](#setup-instructions)
- [Monitoring & Auto-Recovery](#monitoring--auto-recovery)
- [Backup System](#backup-system)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

## <a name="overview"></a>🎯 Overview

| Detail | Value |
|--------|-------|
| **Hostname** | lemongrab |
| **OS** | Linux (Debian-based) |
| **Storage** | 512GB NVMe SSD |
| **Docker Data** | `/home/docker-projects/` (symlinked from `/mnt/ssd/docker-projects/`) |
| **Backups** | `/mnt/ssd/backups/` |

### Hardware Specs

| Component | Specification |
|-----------|---------------|
| **CPU** | Intel Pentium G4560T @ 2.90GHz (2 Cores, 4 Threads) |
| **RAM** | 32GB DDR4 |
| **Storage** | 512GB NVMe SSD |
| **Network** | Gigabit Ethernet |

### What This Server Runs

- **Reverse Proxy**: Caddy (handles routing for all services)
- **Tunnel**: Cloudflare Tunnel (2 replicas for redundancy)
- **Media Server**: Jellyfin (movies, TV, music, books)
- **Cloud Storage**: Nextcloud
- **Password Manager**: Vaultwarden (Bitwarden-compatible)
- **Document Management**: Paperless-ngx (document digitization and organization)
- **Recipe Manager**: KitchenOwl (shopping lists & recipes)
- **File Sharing**: Gokapi
- **Monitoring**: Uptime Kuma
- **Analytics**: GoatCounter
- **Travel Documents**: TravelSync app
- **Bookmarks**: Flask bookmarks service
- **Planning Poker**: Planning poker web application
- **Docker Management**: Portainer
- **Service Dashboard**: Homepage
- **Auto-Updates**: Watchtower (with exclusions)

## <a name="system-requirements"></a>💻 System Requirements

- Lenovo ThinkCentre or similar x86_64 system
- Docker and Docker Compose installed
- SSD storage (recommended for performance)
- Cloudflare account with tunnel configured
- Domain name with DNS configured

## 📚 Documentation

Documentation has been reorganized into a structured format. See [docs/README.md](docs/README.md) for the full index.

**Quick Links:**
- [Infrastructure Summary](docs/reference/infrastructure-summary.md)
- [Backup Strategy](docs/concepts/backup-strategy.md)
- [Common Commands](docs/reference/common-commands.md)
- [How-To Guides](docs/how-to-guides/)

## <a name="running-services"></a>📦 Running Services

### Docker Containers (17 containers, 15 services)

| Service | Port | External URL | Description |
|---------|------|--------------|-------------|
| **Caddy** | 8080 | - | Reverse proxy for all services |
| **Cloudflare Tunnel** | - | - | 2 replicas for redundancy |
| **Jellyfin** | 8096 | jellyfin.gmojsoski.com | Media server |
| **KitchenOwl** | 8092 | shopping.gmojsoski.com | Recipe manager & shopping lists |
| **Vaultwarden** | 8082 | vault.gmojsoski.com | Password manager |
| **Nextcloud** | 8081 | cloud.gmojsoski.com | Cloud storage (PostgreSQL) |
| **Paperless** | 8097 | paperless.gmojsoski.com | Document management (PostgreSQL) |
| **Uptime Kuma** | 3001 | - | Monitoring & alerts |
| **GoatCounter** | 8088 | analytics.gmojsoski.com | Web analytics |
| **Homepage** | 8000 | - | Service dashboard |
| **Portainer** | 9000 | - | Docker management UI |
| **Gokapi** | 8091 | files.gmojsoski.com | File sharing |
| **TravelSync** | 8000 | tickets.gmojsoski.com | Travel document processing |
| **Watchtower** | - | - | Auto-updates (daily 2 AM) |
| **Nginx (Vaultwarden)** | 8083 | - | DELETE→PUT rewrite for iOS |

### Systemd Services

| Service | Port | Description |
|---------|------|-------------|
| **Planning Poker** | 3000 | poker.gmojsoski.com |
| **Bookmarks** | 5000 | bookmarks.gmojsoski.com |
| **Gokapi** | 8091 | files.gmojsoski.com |

## <a name="directory-structure"></a>📁 Directory Structure

```
Pi-version-control/
├── docker/                    # Docker compose files for all services
│   ├── caddy/
│   ├── cloudflared/
│   ├── travelsync/
│   ├── goatcounter/
│   ├── jellyfin/              # (reference only - actual in /home/docker-projects/)
│   ├── kavita/                # (deprecated - using Jellyfin for books)
│   ├── nextcloud/
│   ├── nginx-vaultwarden/
│   ├── paperless/
│   ├── pihole/
│   ├── portainer/
│   ├── uptime-kuma/
│   ├── vaultwarden/
│   └── watchtower/
├── systemd/                   # Systemd service files
│   ├── bookmarks.service
│   ├── cloudflared.service
│   ├── gokapi.service
│   ├── planning-poker.service
│   ├── slack-goatcounter-weekly.service
│   ├── slack-goatcounter-weekly.timer
│   └── slack-pi-monitoring.*
├── scripts/                   # Utility scripts
│   ├── backup-*.sh           # Backup scripts
│   ├── enhanced-health-check.sh
│   ├── import-recipes-to-kitchenowl.py
│   ├── slack-*.sh            # Notification scripts
│   └── archive/              # Old/deprecated scripts
├── restart services/          # Emergency recovery scripts
│   ├── fix-all-services.sh
│   └── emergency-fix.sh
├── cloudflare/
│   └── config.yml
├── fail2ban/
│   └── jail.local.template
├── usefull files/            # Documentation & guides
│   ├── MONITORING_AND_RECOVERY.md
│   ├── KITCHENOWL_RECIPE_IMPORT.md
│   ├── NEXTCLOUD_FRESH_INSTALL.md
│   ├── VAULTWARDEN_SETUP.md
│   └── archive/              # Old documentation
├── docs/                      # Organized documentation (see docs/README.md)
└── README.md                  # This file
```

### Server Directory Structure

```
/home/docker-projects/        # All Docker services
├── caddy/
├── cloudflared/
├── goatcounter/
├── homepage/
├── jellyfin/
├── kitchenowl/
├── nginx-vaultwarden/
├── paperless/
├── portainer/
├── uptime-kuma/
├── vaultwarden/
└── watchtower/

/home/apps/                   # Non-Docker apps
├── nextcloud/
├── gokapi/
├── gokapi-data/
└── bookmarks/

/mnt/ssd/                     # Symlinks + backups
├── docker-projects -> /home/docker-projects
├── apps -> /home/apps
└── backups/
    ├── vaultwarden/
    ├── nextcloud/
    ├── kitchenowl/
    └── travelsync/
```

## <a name="setup-instructions"></a>🚀 Setup Instructions

### 1. Initial System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt-get install docker-compose-plugin -y

# Log out and back in for group changes
```

### 2. Create Directory Structure

```bash
# Create directories
sudo mkdir -p /home/docker-projects
sudo mkdir -p /home/apps/{nextcloud,gokapi,gokapi-data,bookmarks}
sudo mkdir -p /mnt/ssd/backups/{vaultwarden,nextcloud,kitchenowl,travelsync}

# Create symlinks for compatibility
sudo mkdir -p /mnt/ssd
sudo ln -s /home/docker-projects /mnt/ssd/docker-projects
sudo ln -s /home/apps /mnt/ssd/apps

# Set ownership
sudo chown -R $USER:$USER /home/docker-projects
sudo chown -R $USER:$USER /home/apps
```

### 3. Clone This Repository

```bash
cd ~/Desktop/"Cursor projects"
git clone https://github.com/abracadaniel92/lenovo-homelab.git Pi-version-control
```

### 4. Setup Services

See individual setup guides in `usefull files/`:
- `NEXTCLOUD_FRESH_INSTALL.md` - Cloud storage setup
- `VAULTWARDEN_SETUP.md` - Password manager setup
- `KITCHENOWL_RECIPE_IMPORT.md` - Recipe import guide
- `MONITORING_AND_RECOVERY.md` - Health check setup

**Paperless Setup**: See `docker/paperless/README.md` for installation and configuration details.

## <a name="monitoring--auto-recovery"></a>🛡️ Monitoring & Auto-Recovery

The server has a multi-layer monitoring system:

| Layer | Tool | Frequency | Purpose |
|-------|------|-----------|---------|
| 1 | enhanced-health-check.timer | Every 30 seconds | Check & restart all services |
| 2 | Docker restart policies | On failure | Auto-restart containers |
| 3 | Cloudflare Tunnel (2 replicas) | Continuous | Redundant external access |
| 4 | Uptime Kuma | Every 60 seconds | External monitoring & alerts |

### Check Monitoring Status

```bash
# Health check status
systemctl status enhanced-health-check.timer

# View health check logs
tail -50 /var/log/enhanced-health-check.log

# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Emergency Recovery

```bash
# If services go down, run:
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-all-services.sh"
```

## <a name="backup-system"></a>💾 Backup System

**Automated daily backups** run at 2:00 AM for critical services.

### Backup Scripts

```bash
# Run all backups
bash scripts/backup-all-critical.sh

# Individual backups
bash scripts/backup-vaultwarden.sh
bash scripts/backup-nextcloud.sh
bash scripts/backup-kitchenowl.sh
bash scripts/backup-travelsync.sh
```

### Backup Locations

| Service | Location | Importance |
|---------|----------|------------|
| Vaultwarden | `/mnt/ssd/backups/vaultwarden/` | CRITICAL |
| Nextcloud | `/mnt/ssd/backups/nextcloud/` | High |
| Paperless | Docker volumes (data, media) | High |
| KitchenOwl | `/mnt/ssd/backups/kitchenowl/` | Medium |
| Travelsync | `/mnt/ssd/backups/travelsync/` | Medium |

**Retention**: Last 30 backups per service

## <a name="maintenance"></a>🔧 Maintenance

### Update Services

```bash
# Update a Docker service
cd /home/docker-projects/<service>
docker compose pull
docker compose up -d

# View logs
docker compose logs -f

# Restart specific service
docker compose restart
```

### Watchtower Auto-Updates

Watchtower updates containers daily at 2 AM, except:
- **Excluded** (manual updates only): Nextcloud, Vaultwarden, Jellyfin, KitchenOwl

### Check Service Status

```bash
# All Docker containers
docker ps

# Systemd services
systemctl status planning-poker bookmarks gokapi

# Check external access
curl -s -o /dev/null -w "%{http_code}\n" https://jellyfin.gmojsoski.com
```

## <a name="troubleshooting"></a>🐛 Troubleshooting

### Services not accessible externally

```bash
# 1. Check Cloudflare tunnel
docker logs cloudflared-cloudflared-1

# 2. Restart tunnel
cd /home/docker-projects/cloudflared && docker compose restart

# 3. Check Caddy
docker logs caddy
```

### Container keeps restarting

```bash
# Check logs
docker logs <container-name>

# Check health
docker inspect <container-name> --format '{{.State.Health}}'
```

### Database locked errors

```bash
# Stop container first
cd /home/docker-projects/<service>
docker compose stop

# Make changes, then restart
docker compose up -d
```

### Caddy routing issues

```bash
# Validate config
docker exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload config
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## 🔐 Security Notes

1. **Passwords**: Update all default passwords in docker-compose.yml files
2. **Credentials**: Keep Cloudflare tunnel credentials file secure
3. **Firewall**: UFW is configured to allow only necessary ports
4. **Vaultwarden**: Set `SIGNUPS_ALLOWED: "false"` after creating your account

## 📚 Additional Resources

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Jellyfin Documentation](https://jellyfin.org/docs/)
- [Paperless-ngx Documentation](https://docs.paperless-ngx.com/)
- [KitchenOwl GitHub](https://github.com/TomBursch/kitchenowl)
- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Nextcloud Documentation](https://docs.nextcloud.com/)

## <a name="development"></a>🛠️ Development

### Automation Tools
- **Makefile (`lab` alias)**: Shortcuts for health checks, logs, and backups.
    - See [Lab Command Cheat Sheet](restart%20services/LAB_COMMANDS.md) for full usage.
- **Renovate Bot**: Automatically scans and opens PRs for Docker image updates.
- **Pre-commit**: Automatically checks YAML and ensuring script syntax on commit.

### Branching Strategy
- **`main`**: Stable production code.
- **`develop`**: Integration branch for new features and updates.

**Contribution Workflow:**
1.  Checkout `develop`: `git checkout develop`
2.  Create feature branch: `git checkout -b feature/my-cool-feature`
3.  Push and Open PR to `develop`.
4.  Merge `develop` to `main` to release.

## 📄 License

This repository contains configuration files for personal use. Please review and update all credentials and secrets before deploying.

---

**Last Updated**: January 2026  
**System**: Lenovo ThinkCentre (lemongrab)  
**OS**: Linux (Debian)  
**Repository**: https://github.com/abracadaniel92/lenovo-homelab
