# Setup Instructions

End-to-end setup for the ThinkCentre (lemongrab) main server. For the Raspberry Pi DNS node, see [pi-hole-setup.md](pi-hole-setup.md).

## 1. Initial System Setup

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

## 2. Create Directory Structure

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

## 3. Clone This Repository

```bash
git clone https://github.com/abracadaniel92/lenovo-homelab.git Pi-version-control
cd Pi-version-control
```

## 4. Configure Caddy (Reverse Proxy)

The Caddyfile is split into service-specific config files for maintainability and isolation:

- **Main Caddyfile**: `docker/caddy/Caddyfile` — imports all service configs
- **Service configs**: `docker/caddy/config.d/` — split by category:
  - `00-global.caddy` — global error handling
  - `10-gmojsoski-home.caddy` — personal homepage (gmojsoski.com / www → `/srv/site`)
  - `15-centar-srbija-stil.caddy` — css.gmojsoski.com (static site)
  - `20-media.caddy` — media services (Jellyfin, Paperless, Vaultwarden, Immich)
  - `30-storage.caddy` — storage (Nextcloud, TravelSync, Gokapi)
  - `40-communication.caddy` — communication (Mattermost, Planning Poker)
  - `50-utilities.caddy` — utilities (Analytics, Bookmarks, Shopping, Linkwarden, RSS, Budget, Auth)

**Benefit**: a syntax error in one service config is isolated and won't take down routing for the others.

**Cloudflare Tunnel validation**: the hourly health check auto-detects and fixes `127.0.0.1:8080` → `localhost:8080` in the tunnel config (prevents intermittent failures), validates all ingress rules, restarts the tunnel after fixes, and notifies Mattermost on config drift.

## 5. Set Up Services

Per-service setup lives next to each stack and in the docs tree:

- **Paperless**: `docker/paperless/README.md`
- **Mattermost**: `docker/mattermost/README.md`
- **Unbound (recursive DNS)**: `docker/unbound/README.md`
- **Pi Alert (network monitoring)**: `docker/pi-alert/README.md`
- **KitchenOwl recipe import**: [kitchenowl-recipe-import.md](kitchenowl-recipe-import.md)
- **Jellyfin books library**: [jellyfin-books-setup.md](jellyfin-books-setup.md)
- **Monitoring & auto-recovery**: [../concepts/monitoring-and-recovery.md](../concepts/monitoring-and-recovery.md)

**Adding a new service:** follow [SERVICE_ADDITION_CHECKLIST.md](../../SERVICE_ADDITION_CHECKLIST.md). After editing Caddy or Cloudflare config, copy `cloudflare/config.yml` to `~/.cloudflared/config.yml`, restart Caddy and cloudflared, then run `./scripts/verify-services.sh`.

## 6. Docker Profiles & Service Dependencies

Services use Docker Compose profiles for selective startup and dependency ordering.

### Service Profiles

| Profile | Services | Purpose |
|---------|----------|---------|
| **Critical** (no profile) | Caddy, Cloudflared, Vaultwarden, Nextcloud | Always start — essential infrastructure |
| **`media`** | Jellyfin | Media services |
| **`productivity`** | Paperless, Mattermost, Outline | Productivity & collaboration |
| **`utilities`** | Uptime Kuma, GoatCounter, Portainer, Home Assistant | Utility services |
| **`monitoring`** | Uptime Kuma | Monitoring |
| **`databases`** | Nextcloud DB, Mattermost DB, Paperless Redis, Outline DB/Redis | Databases (auto-started with dependents) |
| **`all`** | All profiled services | Start everything |

### Starting Services

```bash
# Critical services only (always running)
cd /home/docker-projects/caddy && docker compose up -d
cd /home/docker-projects/cloudflared && docker compose up -d
cd /home/docker-projects/vaultwarden && docker compose up -d
cd /home/apps/nextcloud && docker compose up -d

# By profile
cd /home/docker-projects/jellyfin && docker compose --profile media up -d
cd /home/docker-projects/mattermost && docker compose --profile productivity up -d
cd /home/docker-projects/paperless && docker compose --profile productivity up -d

# All services (critical + all profiles)
for dir in /home/docker-projects/*/; do
  cd "$dir"
  docker compose up -d 2>/dev/null               # critical (no profile)
  docker compose --profile all up -d 2>/dev/null  # profiled
done
```

### Dependencies & Health Checks

Services wait for their dependencies to be healthy before starting:

- **Nextcloud** → database `service_healthy`
- **Mattermost** → database `service_healthy`
- **Outline** → PostgreSQL + Redis `service_healthy`
- **Paperless** → Redis `service_started`

> Critical services (Caddy, Cloudflared, Vaultwarden, Nextcloud) have no profile and start with a plain `docker compose up -d`. Profiled services start only with `--profile <name>` or `--profile all`.

## See also

- [Test Docker profiles](test-docker-profiles.md)
- [Common commands](../reference/common-commands.md)
- [Troubleshooting](../reference/troubleshooting.md)
- [Backup strategy](../concepts/backup-strategy.md)
