# Lenovo ThinkCentre Configuration & Setup

[![GitHub last commit](https://img.shields.io/github/last-commit/abracadaniel92/lenovo-homelab?style=flat-square&logo=github)](https://github.com/abracadaniel92/lenovo-homelab/commits/main)
[![Docker](https://img.shields.io/badge/containers-30-blue?style=flat-square&logo=docker)](https://github.com/abracadaniel92/lenovo-homelab)


This repository contains all configuration files, scripts, and setup instructions for a self-hosted home lab. The lab consists of two devices: a **Lenovo ThinkCentre** (main server) running all application services, and a **Raspberry Pi 4** (4GB RAM) running Pi-hole for network-wide DNS and ad blocking.

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

### Home Lab Architecture

For a comprehensive infrastructure diagram with all services, network topology, monitoring, and backup systems, see [Infrastructure Diagram](docs/reference/infrastructure-diagram.md).

The home lab consists of two devices working together:

| Device | Hostname | Role | Hardware |
|--------|----------|------|----------|
| **Main Server** | lemongrab | Application services (ThinkCentre) | See below |
| **DNS Server** | pihole | Network DNS & ad blocking (Raspberry Pi 4) | See below |

### ThinkCentre (Main Server) - lemongrab

| Detail | Value |
|--------|-------|
| **Hostname** | lemongrab |
| **OS** | Linux (Debian-based) |
| **Storage** | 512GB NVMe SSD |
| **Docker Data** | `/home/docker-projects/` (symlinked from `/mnt/ssd/docker-projects/`) |
| **Backups** | `/mnt/ssd/backups/` |

#### Hardware Specs

| Component | Specification |
|-----------|---------------|
| **Model** | Lenovo ThinkCentre |
| **CPU** | Intel Pentium G4560T @ 2.90GHz (2 Cores, 4 Threads) |
| **RAM** | 32GB DDR4 |
| **Storage** | 512GB NVMe SSD |
| **Network** | Gigabit Ethernet |

### Raspberry Pi 4 (DNS Server) - pihole

| Detail | Value |
|--------|-------|
| **Hostname** | pihole |
| **Model** | Raspberry Pi 4 Model B |
| **RAM** | 4GB |
| **OS** | Raspberry Pi OS (Debian-based) |
| **Network** | Gigabit Ethernet (primary), WiFi (secondary) |
| **Purpose** | Pi-hole DNS server & network-wide ad blocking |
| **Configuration** | Docker-based deployment |

### What This Lab Runs

**On ThinkCentre (lemongrab):**
- **Reverse Proxy**: Caddy (handles routing for all services)
- **Tunnel**: Cloudflare Tunnel (2 replicas for redundancy)
- **Media Server**: Jellyfin (movies, TV, music, books)
- **Cloud Storage**: Nextcloud
- **Password Manager**: Vaultwarden (Bitwarden-compatible)
- **Document Management**: Paperless-ngx (document digitization and organization)
- **Knowledge Base**: Outline (wiki and documentation)
- **Team Communication**: Mattermost (Slack alternative)
- **Recipe Manager**: KitchenOwl (shopping lists & recipes)
- **File Sharing**: Gokapi
- **Monitoring**: Uptime Kuma
- **Analytics**: GoatCounter
- **Travel Documents**: TravelSync app
- **Bookmarks**: Flask bookmarks service
- **Bookmark Manager**: Linkwarden (bookmarks with web archiving)
- **Planning Poker**: Planning poker web application
- **Docker Management**: Portainer
- **Service Dashboard**: Homepage
- **Home Automation**: Home Assistant (local only)
- **Auto-Updates**: Watchtower (with exclusions)

**On Raspberry Pi 4 (pihole):**
- **DNS Server**: Pi-hole (network-wide DNS & ad blocking)
- **Recursive DNS Resolver**: Unbound (privacy-focused recursive DNS, queries root servers directly)
- **Network Monitoring**: Pi Alert (device discovery, network monitoring, Mattermost alerts)
- **Ad Blocking**: Network-wide ad blocking with custom blocklists
- **Monitoring**: Uptime Kuma (secondary instance for redundancy)
- **Note**: Do NOT add Local DNS Records for `*.YOUR DOMAIN` domains using Cloudflare Tunnel - all devices should use Cloudflare DNS for consistent access

## <a name="system-requirements"></a>💻 System Requirements

**Main Server (ThinkCentre):**
- Lenovo ThinkCentre or similar x86_64 system
- Docker and Docker Compose installed
- SSD storage (recommended for performance)
- Cloudflare account with tunnel configured
- Domain name with DNS configured

**DNS Server (Raspberry Pi):**
- Raspberry Pi 4 (4GB RAM recommended)
- Docker and Docker Compose installed
- Ethernet connection (WiFi optional)
- Router with configurable DHCP DNS settings

## 📚 Documentation

Documentation has been reorganized into a structured format. See [docs/README.md](docs/README.md) for the full index.

**Quick Links:**
- [Infrastructure Summary](docs/reference/infrastructure-summary.md)
- [Backup Strategy](docs/concepts/backup-strategy.md)
- [Common Commands](docs/reference/common-commands.md)
- [How-To Guides](docs/how-to-guides/)
- [Pi-hole Setup Guide](docs/how-to-guides/pi-hole-setup.md) - Raspberry Pi 4 DNS & ad blocking setup
- [Unbound Setup](docker/unbound/README.md) - Recursive DNS resolver configuration
- [Pi Alert Setup](docker/pi-alert/README.md) - Network monitoring & device discovery

## <a name="running-services"></a>📦 Running Services

### Docker Containers (30 containers, 21 services)

| Service | External URL | Description |
|---------|--------------|-------------|
| **Caddy** | - | Reverse proxy for all services |
| **Cloudflare Tunnel** | - | 2 replicas for redundancy |
| **Jellyfin** | jellyfin.gmojsoski.com | Media server |
| **KitchenOwl** | shopping.gmojsoski.com | Recipe manager & shopping lists |
| **Vaultwarden** | vault.gmojsoski.com | Password manager |
| **Nextcloud** | cloud.gmojsoski.com | Cloud storage (PostgreSQL) |
| **Paperless** | paperless.gmojsoski.com | Document management (PostgreSQL) |
| **Outline** | - | Wiki & knowledge base (local only, PostgreSQL + Redis) |
| **Mattermost** | mattermost.gmojsoski.com | Team communication platform (Slack alternative, PostgreSQL) |
| **Clawdbot** | - | AI assistant bot for Mattermost (local only, Google Gemini API) |
| **Uptime Kuma** | - | Monitoring & alerts |
| **GoatCounter** | analytics.gmojsoski.com | Web analytics |
| **Homepage** | - | Service dashboard |
| **Portainer** | - | Docker management UI |
| **Gokapi** | files.gmojsoski.com | File sharing |
| **TravelSync** | tickets.gmojsoski.com | Travel document processing |
| **Linkwarden** | linkwarden.gmojsoski.com | Bookmark manager with web archiving |
| **Portfolio** | portfolio.gmojsoski.com | Ivana's portfolio site (Vue.js) |
| **Home Assistant** | - | Home automation (local only) |
| **Watchtower** | - | Auto-updates (daily 2 AM) |
| **Nginx (Vaultwarden)** | - | DELETE→PUT rewrite for iOS |

### Systemd Services

| Service | External URL | Description |
|---------|--------------|-------------|
| **Planning Poker** | poker.gmojsoski.com | Planning poker web application |
| **Bookmarks** | bookmarks.gmojsoski.com | Flask bookmarks service |
| **Gokapi** | files.gmojsoski.com | File sharing |

## <a name="directory-structure"></a>📁 Directory Structure

```
Pi-version-control/
├── docker/                    # Docker compose files for all services
│   ├── caddy/
│   │   ├── Caddyfile          # Main Caddyfile (imports config.d files)
│   │   └── config.d/          # Split service-specific configs
│   │       ├── 10-portfolio.caddyfile
│   │       ├── 20-media.caddyfile
│   │       ├── 30-storage.caddyfile
│   │       ├── 40-communication.caddyfile
│   │       └── 50-utilities.caddyfile
│   ├── cloudflared/
│   ├── travelsync/
│   ├── goatcounter/
│   ├── jellyfin/              # (reference only - actual in /home/docker-projects/)
│   ├── nextcloud/
│   ├── nginx-vaultwarden/
│   ├── paperless/
│   ├── mattermost/
│   ├── clawdbot/
│   ├── pihole/
│   ├── pi-alert/              # Network monitoring & device discovery
│   ├── portainer/
│   ├── homeassistant/         # Home automation (local only)
│   ├── unbound/               # Recursive DNS resolver
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
│   ├── verify-backups.sh     # Automated backup verification
│   ├── enhanced-health-check.sh  # Health check with auto-recovery
│   ├── deploy-health-check.sh    # Deploy health check to production
│   ├── test-step5-profiles.sh    # Test Docker profiles
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
├── mattermost/
├── nginx-vaultwarden/
├── paperless/
├── portainer/
├── homeassistant/
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
# Clone to your desired location
git clone https://github.com/abracadaniel92/lenovo-homelab.git Pi-version-control
cd Pi-version-control
```

### 4. Configure Caddy (Reverse Proxy)

**Caddyfile Structure**:
The Caddyfile has been split into service-specific config files for better maintainability and isolation:

- **Main Caddyfile**: `docker/caddy/Caddyfile` - Imports all service configs
- **Service Configs**: `docker/caddy/config.d/` - Split by category:
  - `10-portfolio.caddyfile` - Portfolio site
  - `20-media.caddyfile` - Media services (Jellyfin, Paperless, Vaultwarden)
  - `30-storage.caddyfile` - Storage services (Nextcloud, TravelSync, Gokapi)
  - `40-communication.caddyfile` - Communication (Mattermost, Planning Poker)
  - `50-utilities.caddyfile` - Utilities (Analytics, Bookmarks, Shopping, Linkwarden)

**Benefits**: Service config errors are isolated, easier to maintain, and prevent cascading failures.

**Cloudflare Tunnel Validation**:
- Health check automatically validates Cloudflare Tunnel configuration
- Auto-detects and fixes `127.0.0.1:8080` → `localhost:8080` (prevents intermittent failures)
- Validates all ingress rules use `localhost:8080`
- Auto-restarts tunnel after fixes
- Sends Mattermost notifications for configuration issues

### 5. Setup Services

See individual setup guides in `usefull files/`:
- `NEXTCLOUD_FRESH_INSTALL.md` - Cloud storage setup
- `VAULTWARDEN_SETUP.md` - Password manager setup
- `KITCHENOWL_RECIPE_IMPORT.md` - Recipe import guide
- `MONITORING_AND_RECOVERY.md` - Health check setup

**Paperless Setup**: See `docker/paperless/README.md` for installation and configuration details.

**Mattermost Setup**: See `docker/mattermost/README.md` for installation and configuration details.

### 6. Docker Profiles & Service Dependencies

Services are organized using Docker Compose profiles for selective startup and proper dependency ordering.

#### Service Profiles

| Profile | Services | Purpose |
|---------|----------|---------|
| **Critical** (no profile) | Caddy, Cloudflared, Vaultwarden, Nextcloud | Always start - essential infrastructure |
| **`media`** | Jellyfin | Media services |
| **`productivity`** | Paperless, Mattermost, Outline | Productivity and collaboration tools |
| **`utilities`** | Uptime Kuma, GoatCounter, Portainer, Home Assistant | Utility services |
| **`monitoring`** | Uptime Kuma | Monitoring services |
| **`databases`** | Nextcloud DB, Mattermost DB, Paperless Redis, Outline DB/Redis | Database services (auto-started with dependent services) |
| **`all`** | All profiled services | Convenience profile to start all services |

#### Starting Services

```bash
# Start critical services only (always running)
cd /home/docker-projects/caddy && docker compose up -d
cd /home/docker-projects/cloudflared && docker compose up -d
cd /home/docker-projects/vaultwarden && docker compose up -d
cd /home/apps/nextcloud && docker compose up -d

# Start services by profile
cd /home/docker-projects/jellyfin && docker compose --profile media up -d
cd /home/docker-projects/mattermost && docker compose --profile productivity up -d
cd /home/docker-projects/paperless && docker compose --profile productivity up -d

# Start all profiled services
for dir in /home/docker-projects/*/; do
  cd "$dir" && docker compose --profile all up -d 2>/dev/null
done

# Start all services (critical + all profiles)
for dir in /home/docker-projects/*/; do
  cd "$dir"
  docker compose up -d 2>/dev/null  # Critical services (no profile)
  docker compose --profile all up -d 2>/dev/null  # Profiled services
done
```

#### Service Dependencies & Health Checks

Services now properly wait for their dependencies to be healthy before starting:

- **Nextcloud**: App waits for database health check (`service_healthy`)
- **Mattermost**: App waits for database health check (`service_healthy`)
- **Outline**: App waits for PostgreSQL and Redis health checks (`service_healthy`)
- **Paperless**: App waits for Redis to start (`service_started`)

#### Example: Selective Startup

```bash
# Start only critical services during maintenance
cd /home/docker-projects/caddy && docker compose up -d
cd /home/docker-projects/cloudflared && docker compose up -d

# Start only media services
cd /home/docker-projects/jellyfin && docker compose --profile media up -d

# Start productivity tools when needed
cd /home/docker-projects/mattermost && docker compose --profile productivity up -d
cd /home/docker-projects/paperless && docker compose --profile productivity up -d
```

**Note**: Critical services (Caddy, Cloudflared, Vaultwarden, Nextcloud) have no profiles and always start when you run `docker compose up -d` without profiles. Profiled services only start when explicitly started with `--profile <profile>` or `--profile all`.

## <a name="monitoring--auto-recovery"></a>🛡️ Monitoring & Auto-Recovery

The server has a multi-layer monitoring system:

| Layer | Tool | Frequency | Purpose |
|-------|------|-----------|---------|
| 1 | enhanced-health-check.timer | Every 3 minutes | Check & restart all services, monitor resources |
| 2 | Docker restart policies | On failure | Auto-restart containers |
| 3 | Cloudflare Tunnel (2 replicas) | Continuous | Redundant external access |
| 4 | Uptime Kuma | Every 60 seconds | External monitoring & alerts |
| 5 | Pi health reports | Every 5 days | System health summary to Mattermost |
| 6 | Analytics reports | Weekly (Sunday 10 AM) | Portfolio analytics summary to Mattermost |
| 7 | Portfolio Update | Manual (via `make portfolio-update`) | Sync portfolio from GitHub |

### Health Check Features

The enhanced health check (`enhanced-health-check.sh`) includes:

**Configuration Integrity**:
- Cloudflare Tunnel config validation and auto-fix (`127.0.0.1` → `localhost`)
- Caddyfile validation (checks main file and all split config files)
- UDP buffer size optimization

**Resource Monitoring**:
- **Memory Usage**: Monitors system memory (warns at 85%, critical at 90%)
- **Disk Space**: Monitors `/` and `/mnt/ssd` (warns at 80%, critical at 90%)
- Mattermost notifications with throttling (once per hour per issue)

**Service Health**:
- Docker service checks and auto-restart
- Caddy reverse proxy health
- Cloudflare Tunnel status
- External access verification

**Backup Verification**:
- Automated backup integrity checks (runs once per hour)
- Verifies backup age, size, and integrity
- Alerts for missing or corrupted backups

### Mattermost Notifications

All monitoring alerts and reports are sent to Mattermost channels via webhooks:

- **Health Check Alerts**: `@here` for warnings, `@all` for critical issues
  - Memory usage alerts (warning ≥85%, critical ≥90%)
  - Disk space alerts (warning ≥80%, critical ≥90%)
  - Service failure alerts
  - Configuration drift alerts (Cloudflare/Caddyfile)
- **Backup Verification Alerts**: `@all` for missing/corrupted backups, `@here` for old backups
- **System Health Reports**: `@here` - Sent every 5 days with system stats (CPU, memory, disk, Docker status)
- **Analytics Reports**: `@here` - Weekly portfolio analytics summary

**Bot Usernames**:
- Health checks: "System Bot"
- System reports: "System Bot"
- Analytics: "Analytics Bot"

**Configuration**: Requires System Console → Integrations → Enable "Override usernames" setting.

### Check Monitoring Status

```bash
# Health check status
systemctl status enhanced-health-check.timer

# View health check logs
tail -50 /var/log/enhanced-health-check.log

# Manually trigger health check (from repo directory)
make health
# or
lab-make health

# Verify health check configuration (from repo directory)
make health-verify
# or
lab-make health-verify

# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Emergency Recovery

```bash
# If services go down, run (from repo directory):
bash "restart services/fix-all-services.sh"
```

## <a name="backup-system"></a>💾 Backup System

**Automated daily backups** run at 2:00 AM for critical services, with offsite sync to Backblaze B2 at 3:00 AM.

### Backup Scripts

```bash
# Run all backups
bash scripts/backup-all-critical.sh

# Individual backups
bash scripts/backup-vaultwarden.sh
bash scripts/backup-nextcloud.sh
bash scripts/backup-kitchenowl.sh
bash scripts/backup-travelsync.sh
bash scripts/backup-linkwarden.sh
```

### Backup Verification

**Automated verification** runs hourly via health check:
- Checks backup integrity (tar.gz extraction test)
- Verifies backup age (alerts if backups are too old)
- Validates backup file sizes
- Detects missing backups
- Sends Mattermost notifications for issues

**Manual verification**:
```bash
# Run backup verification manually
bash scripts/verify-backups.sh

# View verification log
tail -f ~/backup-verification.log
```

**Service-specific thresholds**:
- **Vaultwarden** (CRITICAL): 48 hours max age
- **Nextcloud** (CRITICAL): 48 hours max age
- **TravelSync** (IMPORTANT): 72 hours max age
- **KitchenOwl** (IMPORTANT): 72 hours max age
- **Linkwarden** (MEDIUM): 96 hours max age

### Backup Locations

| Service | Location | Importance |
|---------|----------|------------|
| Vaultwarden | `/mnt/ssd/backups/vaultwarden/` | CRITICAL |
| Nextcloud | `/mnt/ssd/backups/nextcloud/` | High |
| Paperless | Docker volumes (data, media) | High |
| KitchenOwl | `/mnt/ssd/backups/kitchenowl/` | Medium |
| Travelsync | `/mnt/ssd/backups/travelsync/` | Medium |
| Linkwarden | `/mnt/ssd/backups/linkwarden/` | Medium |

### Retention Policy

Backups use a **multi-tier retention system** (not a flat 30-day retention):

| Tier | Retention | Description |
|------|-----------|-------------|
| **Hourly** | Last 6 backups | Backups within 6 hours |
| **Daily** | Last 5 backups | One backup per day (within 5 days) |
| **Weekly** | Last 4 backups | One backup per week (within 4 weeks) |
| **Monthly** | Last 2 backups | One backup per month (within 2 months) |
| **Yearly** | Last 1 backup | One backup per year (within 1 year) |

**Total backups kept**: Typically ~18 backups per service, automatically managed by tier.

### Offsite Backup (Backblaze B2)

All local backups are automatically synced to **Backblaze B2** cloud storage:

- **Provider**: Backblaze B2 Cloud Storage
- **Bucket**: `Goce-Lenovo`
- **Sync Schedule**: Daily at 3:00 AM (after local backups complete)
- **Sync Script**: `/usr/local/bin/sync-backups-to-b2.sh`
- **Tool**: rclone
- **Remote**: `b2-backup:Goce-Lenovo/`

**Manual sync**:
```bash
# Sync backups to Backblaze B2
sudo /usr/local/bin/sync-backups-to-b2.sh

# Check B2 sync status
rclone ls b2-backup:Goce-Lenovo/

# View sync logs
tail -f /var/log/rclone-sync.log
```

**Setup Backblaze B2** (if not already configured):
```bash
bash scripts/setup-backblaze-b2-backup.sh
```

See also: [Backup Strategy Documentation](docs/concepts/backup-strategy.md)

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

### Resource Limits

Docker containers have resource limits configured to prevent resource exhaustion:

| Service | Memory Limit | CPU Limit |
|---------|--------------|-----------|
| **Jellyfin** | 8GB | 2.0 CPUs |
| **Nextcloud** (app) | 4GB | 1.0 CPU |
| **Nextcloud** (db) | 2GB | 1.0 CPU |
| **Mattermost** (app) | 4GB | 1.0 CPU |
| **Mattermost** (db) | 2GB | 1.0 CPU |
| **Paperless** (webserver) | 2GB | 1.0 CPU |
| **Paperless** (broker) | 512MB | 0.5 CPU |
| **Home Assistant** | 2GB | 1.0 CPU |

Resource limits are configured in each service's `docker-compose.yml` using `mem_limit`, `memswap_limit`, and `cpus` directives.

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
# Validate config (checks main Caddyfile and all split config files)
cd /home/docker-projects/caddy
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload config
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# View split config files
ls -la /home/docker-projects/caddy/config.d/

# Check specific service config
cat /home/docker-projects/caddy/config.d/20-media.caddyfile
```

**Caddyfile Structure**:
- Main config: `docker/caddy/Caddyfile` (imports all split configs)
- Split configs: `docker/caddy/config.d/*.caddyfile` (service-specific)
- Benefits: Isolated configs prevent cascading failures

### Cloudflare Tunnel issues

```bash
# Check tunnel status
docker ps --filter "name=cloudflared"

# View tunnel logs
docker logs cloudflared-cloudflared-1

# Restart tunnel
cd /home/docker-projects/cloudflared && docker compose restart

# Validate config (auto-fixed by health check)
cat ~/.cloudflared/config.yml | grep -E "service|ingress"

# Manual fix: Ensure all rules use localhost:8080 (not 127.0.0.1:8080)
sed -i 's/127.0.0.1:8080/localhost:8080/g' ~/.cloudflared/config.yml
```

**Cloudflare Validation**:
- Health check automatically detects and fixes `127.0.0.1:8080` → `localhost:8080`
- Prevents intermittent connection failures
- Validates all ingress rules use `localhost:8080`
- Auto-restarts tunnel after fixes

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
**Home Lab**: Lenovo ThinkCentre (lemongrab) + Raspberry Pi 4 (pihole)  
**OS**: Linux (Debian-based)  
**Repository**: https://github.com/abracadaniel92/lenovo-homelab
