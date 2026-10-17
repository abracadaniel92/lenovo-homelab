# Lenovo ThinkCentre Home Lab

[![GitHub last commit](https://img.shields.io/github/last-commit/abracadaniel92/lenovo-homelab?style=flat-square&logo=github)](https://github.com/abracadaniel92/lenovo-homelab/commits/main)
[![Docker](https://img.shields.io/badge/containers-33-blue?style=flat-square&logo=docker)](https://github.com/abracadaniel92/lenovo-homelab)

Configuration, scripts, and setup for a self-hosted home lab on three devices: a **Lenovo ThinkCentre** (`lemongrab`) running all application services, a **Raspberry Pi 4** (`pihole`) running Pi-hole + Unbound for network-wide DNS and ad blocking, and a **Terra mini PC** (`cricket`) at the office holding an offsite backup copy.

> **📚 Full documentation lives in [`docs/`](docs/README.md)**: this README is the orientation map. Setup, monitoring, backups, troubleshooting, and per-topic guides are all under `docs/`.

## Architecture

| Device | Hostname | Role | Hardware |
|--------|----------|------|----------|
| **Main server** | lemongrab | Application services | Lenovo ThinkCentre M710q, i5-7500T, 32GB RAM |
| **DNS server** | pihole | Network DNS & ad blocking, secondary Uptime Kuma | Raspberry Pi 4 Model B (4GB) |
| **Offsite backup** | cricket (the Terra) | restic target over WireGuard, at the office | Terra PC-Micro 3000 (fanless), 2 TB USB HDD |

lemongrab is the WireGuard hub (`wg0`); the Terra connects to it, and remote SSH to the Terra goes through lemongrab.

For the full network topology, see [docs/reference/infrastructure-diagram.md](docs/reference/infrastructure-diagram.md).

### ThinkCentre (lemongrab) storage

| Mount | Device | Use |
|-------|--------|-----|
| `/` (101 GB) | 512GB NVMe SSD | OS only, keep it lean |
| `/home` (368 GB) | same NVMe | Docker data root (`/home/docker-data/`), stacks (`/home/docker-projects/`, `/home/apps/`) |
| `/mnt/ssd_1tb` | 1TB WD laptop HDD (WD10SPZX) | Immich library, Kiwix, Pi backups. The name is historical: it is not an SSD |
| `/mnt/ssd/backups` | folder on `/` | Local service backups (small). `/mnt/ssd/docker-projects` and `/mnt/ssd/apps` are symlinks into `/home` |

The old USB HDDs (mergerfs `/mnt/storage` pool, `/mnt/disk_old`) were unplugged on 2026-09-26. Don't put data there.

## Services

Reverse proxy is **Caddy** (`localhost:8080`), fronted by a **Cloudflare Tunnel** (2 replicas). The authoritative port list is [docs/reference/port-map.md](docs/reference/port-map.md); the full service overview is [docs/reference/infrastructure-summary.md](docs/reference/infrastructure-summary.md).

### On lemongrab (Docker)

| Service | External URL | Description |
|---------|--------------|-------------|
| Jellyfin | jellyfin.gmojsoski.com | Media server |
| Nextcloud | cloud.gmojsoski.com | Cloud storage |
| Immich | immich.gmojsoski.com | Photo & video backup |
| Vaultwarden | vault.gmojsoski.com | Password manager |
| Paperless-ngx | paperless.gmojsoski.com | Document management |
| Mattermost | mattermost.gmojsoski.com | Team chat |
| Linkwarden | linkwarden.gmojsoski.com | Bookmarks + web archiving |
| FreshRSS | rss.gmojsoski.com | RSS aggregator |
| GoatCounter | analytics.gmojsoski.com | Web analytics |
| TravelSync | tickets.gmojsoski.com | Travel document processing |
| Cal | cal.gmojsoski.com | Scheduling / booking pages |
| Outline | local only | Wiki / knowledge base |
| Home Assistant + Mosquitto | local only | Home automation, MQTT broker |
| Stirling PDF | local only (`:8095`) | PDF toolkit |
| Kiwix | local only (`:8089`) | Offline Wikipedia/library |
| Uptime Kuma / Portainer / Homepage | local only | Monitoring / Docker UI / dashboard |

Systemd-managed: **Planning Poker** (poker.gmojsoski.com), **Bookmarks** (bookmarks.gmojsoski.com).

Nothing auto-updates. `update-check.timer` pushes a weekly list of images with a
newer build, and **Renovate** opens PRs against this repo; every update is applied
by hand, one service at a time. Watchtower was removed on 2026-09-25 (unmaintained,
had not run since March).

### On pihole (Raspberry Pi 4)

- **Pi-hole**: network-wide DNS & ad blocking
- **Unbound**: recursive DNS resolver (queries root servers directly)
- **Unbound** is Pi-hole's only upstream (no Google/Cloudflare fallback), with DNSSEC
- **Uptime Kuma v2**: secondary monitoring instance for redundancy
- **fail2ban**: SSH jail (port 222), config in [`pihole/fail2ban/pi.local`](pihole/fail2ban/pi.local)
- **Nightly backup** to lemongrab (02:30, write-only rsync), then offsite to B2 with the rest

See [pihole/README.md](pihole/README.md) and its own [troubleshooting log](pihole/troubleshooting-log.md).

### On the Terra (offsite)

restic rest-server over WireGuard, receiving the Immich library and `/mnt/ssd/backups`
from lemongrab. The 2 TB drive was seeded over USB (snapshot of 133 GiB, `restic check`
clean) and moves to the office on 2026-10-19. See [terra/README.md](terra/README.md).

## Backups and monitoring

- **Local**: `scripts/backup-engine.sh` + one `scripts/backup.d/<service>.conf` per
  service, daily 02:00, into `/mnt/ssd/backups/`. `scripts/restore-drill.sh` proves the
  archives actually restore.
- **Offsite, two places**: Backblaze B2 nightly (03:00, rclone crypt), and the Terra
  (restic). So photos exist on lemongrab, the Terra, and B2.
- **Health**: `enhanced-health-check.timer` runs hourly through the `scripts/health.d/`
  modules (Caddy, tunnel, containers, SMART, backup and offsite freshness) and
  auto-recovers what it can.
- **Alerts**: critical failures push to the phone via **ntfy**; a **healthchecks.io**
  dead man's switch fires if the health check itself stops running; Uptime Kuma runs on
  both lemongrab and the Pi.
- Caddy writes access logs with real visitor IPs (since 2026-10-08).

Details: [concepts/backup-strategy.md](docs/concepts/backup-strategy.md),
[concepts/monitoring-and-recovery.md](docs/concepts/monitoring-and-recovery.md).

## Quick start

```bash
git clone https://github.com/abracadaniel92/lenovo-homelab.git Pi-version-control
cd Pi-version-control
```

> **On lemongrab this checkout is live code.** `/opt/homelab` is a symlink to it, and
> the health check, backups and `/usr/local/bin` scripts all run from it. So
> `git checkout` and `git pull` there are deploys: keep it on `main`. Never put a path
> with a space into a unit file, cron line or script (that broke everything for eight
> months, log 2026-09-25).

Then follow [docs/how-to-guides/setup.md](docs/how-to-guides/setup.md) (Docker install → directories → Caddy → services → profiles). Add a new service via [SERVICE_ADDITION_CHECKLIST.md](SERVICE_ADDITION_CHECKLIST.md).

## Documentation

Everything is indexed in **[docs/README.md](docs/README.md)**. Highlights:

| Topic | Doc |
|-------|-----|
| Setup (end to end) | [how-to-guides/setup.md](docs/how-to-guides/setup.md) |
| Monitoring & auto-recovery | [concepts/monitoring-and-recovery.md](docs/concepts/monitoring-and-recovery.md) |
| Backups & retention | [concepts/backup-strategy.md](docs/concepts/backup-strategy.md) |
| Troubleshooting & maintenance | [reference/troubleshooting.md](docs/reference/troubleshooting.md) |
| Common commands | [reference/common-commands.md](docs/reference/common-commands.md) |
| Lab command cheat sheet | [reference/lab-commands.md](docs/reference/lab-commands.md) |
| Port map | [reference/port-map.md](docs/reference/port-map.md) |
| LAN / VPN service URLs | [reference/lan-and-vpn-service-urls.md](docs/reference/lan-and-vpn-service-urls.md) |
| Incident log (lemongrab) | [reference/troubleshooting-log.md](docs/reference/troubleshooting-log.md) |
| Incident logs (Pi, Terra) | [pihole/](pihole/troubleshooting-log.md), [terra/](terra/troubleshooting-log.md) |

## Repository layout

```
docker/        # Compose stacks; many mirrored from live paths by scripts/mirror-live-compose.sh (caddy/config.d/ holds split *.caddy snippets)
systemd/       # Service + timer units (health checks, backups, etc.)
scripts/       # Backups, health checks (health.d/), offsite sync, notifications. LIVE on lemongrab via /opt/homelab
restart services/  # Emergency recovery scripts (fix-all-services.sh, fix-external-access.sh)
cloudflare/    # Cloudflare Tunnel ingress config
fail2ban/      # fail2ban jail config (lemongrab SSH)
ssh/           # sshd drop-ins (lemongrab key-only login)
docs/          # All documentation (see docs/README.md)
pihole/        # Raspberry Pi DNS node: Pi-hole + Unbound stacks, fail2ban, setup guide
terra/         # Terra PC at the office: offsite restic target, WireGuard, watchdog
.cursor/       # Agent rules (governance, lesson capture), skills, lesson proposals
```

> Live server paths differ from the repo: services run from `/home/docker-projects/` and `/home/apps/`, with `/mnt/ssd/` symlinks and `/mnt/ssd/backups/`.

## Security

See **[SECURITY.md](SECURITY.md)** (also under GitHub **Security → Policy**). Key practices: no default passwords, secured Cloudflare credentials, UFW firewall, and `SIGNUPS_ALLOWED: "false"` on Vaultwarden after account creation.

## Development

- **Makefile** (`lab` alias): health checks, logs, backups; see [reference/lab-commands.md](docs/reference/lab-commands.md).
- **Renovate**: automated PRs for Docker image updates.
- **pre-commit**: YAML/shell checks on commit.
- **Commits and branches**: small atomic commits (one logical change each, with its log entry). lemongrab commits straight to `main`; other machines open a PR from `feature/<date>-<name>` into `main` (never squash-merged). See the `prepare-pull-request` skill.
- **AI agents**: start with [CLAUDE.md](CLAUDE.md) and [`.cursor/rules/`](.cursor/rules/). Runbooks are in `.cursor/skills/`; agents propose changes to their own guidance in `.cursor/proposals/` and blog post ideas in `.cursor/blog/`; the owner reviews both weekly (`weekly-review`).

## License

Configuration for personal use. Review and update all credentials and secrets before deploying.

---

**Home Lab**: Lenovo ThinkCentre (lemongrab) + Raspberry Pi 4 (pihole) + Terra (cricket) · Linux (Debian-based) · [github.com/abracadaniel92/lenovo-homelab](https://github.com/abracadaniel92/lenovo-homelab)
