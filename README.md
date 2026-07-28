# Lenovo ThinkCentre Home Lab

[![GitHub last commit](https://img.shields.io/github/last-commit/abracadaniel92/lenovo-homelab?style=flat-square&logo=github)](https://github.com/abracadaniel92/lenovo-homelab/commits/main)
[![Docker](https://img.shields.io/badge/containers-30-blue?style=flat-square&logo=docker)](https://github.com/abracadaniel92/lenovo-homelab)

Configuration, scripts, and setup for a self-hosted home lab on two devices: a **Lenovo ThinkCentre** (`lemongrab`) running all application services, and a **Raspberry Pi 4** (`pihole`) running Pi-hole + Unbound for network-wide DNS and ad blocking.

> **📚 Full documentation lives in [`docs/`](docs/README.md)** — this README is the orientation map. Setup, monitoring, backups, troubleshooting, and per-topic guides are all under `docs/`.

## Architecture

| Device | Hostname | Role | Hardware |
|--------|----------|------|----------|
| **Main server** | lemongrab | Application services | Lenovo ThinkCentre M710q — i5-7500T, 32GB RAM |
| **DNS server** | pihole | Network DNS & ad blocking | Raspberry Pi 4 Model B (4GB) |

For the full network topology, see [docs/reference/infrastructure-diagram.md](docs/reference/infrastructure-diagram.md).

### ThinkCentre (lemongrab) storage

| Mount | Device | Use |
|-------|--------|-----|
| `/`, `/home` | 512GB NVMe SSD | OS + Docker data (`/home/docker-data/`) |
| `/mnt/ssd_1tb` | 1TB SATA SSD | Sensitive/primary data (e.g. Immich) |
| `/mnt/storage` | 1TB + 2TB (mergerfs, ~3TB) | Archives (e.g. Kiwix) |
| `/mnt/ssd/backups` | — | Local backups |
| `/mnt/disk_old` | 500GB (2013) | Legacy / non-critical |

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
| KitchenOwl | shopping.gmojsoski.com | Recipes & shopping lists |
| Mattermost | mattermost.gmojsoski.com | Team chat (+ Clawdbot AI, local Ollama) |
| Linkwarden | linkwarden.gmojsoski.com | Bookmarks + web archiving |
| FreshRSS | rss.gmojsoski.com | RSS aggregator |
| Actual Budget | budget.gmojsoski.com | Personal finance |
| GoatCounter | analytics.gmojsoski.com | Web analytics |
| Gokapi | files.gmojsoski.com | File sharing |
| TravelSync | tickets.gmojsoski.com | Travel document processing |
| Centar Srbija Stil | css.gmojsoski.com | Static site |
| Outline | local only | Wiki / knowledge base |
| Home Assistant | local only | Home automation |
| Stirling PDF | local only (`:8095`) | PDF toolkit |
| Kiwix | local only (`:8089`) | Offline Wikipedia/library |
| Android Emulator | local only (`:8233`) | ws-scrcpy browser control |
| Uptime Kuma / Portainer / Homepage | local only | Monitoring / Docker UI / dashboard |
| Watchtower | — | Auto-updates (daily 2 AM, with exclusions) |

Systemd-managed: **Planning Poker** (poker.gmojsoski.com), **Bookmarks** (bookmarks.gmojsoski.com), **Gokapi**.

> A private **MCP Knowledge** server (`knowledge-mcp`, host `:8001`, **LAN only**) is also deployed — see [docs/how-to-guides/mcp-knowledge-server.md](docs/how-to-guides/mcp-knowledge-server.md). Its code lives in the separate `mcp_server` project.

### On pihole (Raspberry Pi 4)

- **Pi-hole** — network-wide DNS & ad blocking
- **Unbound** — recursive DNS resolver (queries root servers directly)
- **Pi Alert** — device discovery & network monitoring (Mattermost alerts)
- **Uptime Kuma** — secondary monitoring instance for redundancy

See [docs/how-to-guides/pi-hole-setup.md](docs/how-to-guides/pi-hole-setup.md).

## Quick start

```bash
git clone https://github.com/abracadaniel92/lenovo-homelab.git Pi-version-control
cd Pi-version-control
```

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
| Incident log | [reference/troubleshooting-log.md](docs/reference/troubleshooting-log.md) |

## Repository layout

```
docker/        # Per-service Docker Compose stacks (caddy/config.d/ holds split *.caddy snippets)
systemd/       # Service + timer units (health checks, weekly refreshes, etc.)
scripts/       # Backups, health checks, auto-recovery, notifications
restart services/  # Emergency recovery scripts (fix-all-services.sh, fix-external-access.sh)
cloudflare/    # Cloudflare Tunnel ingress config
docs/          # All documentation (see docs/README.md)
```

> Live server paths differ from the repo: services run from `/home/docker-projects/` and `/home/apps/`, with `/mnt/ssd/` symlinks and `/mnt/ssd/backups/`.

## Security

See **[SECURITY.md](SECURITY.md)** (also under GitHub **Security → Policy**). Key practices: no default passwords, secured Cloudflare credentials, UFW firewall, and `SIGNUPS_ALLOWED: "false"` on Vaultwarden after account creation.

## Development

- **Makefile** (`lab` alias) — health checks, logs, backups; see [reference/lab-commands.md](docs/reference/lab-commands.md).
- **Renovate** — automated PRs for Docker image updates.
- **pre-commit** — YAML/shell checks on commit.
- **Branching** — `main` (stable) ← `develop` (integration) ← `feature/*`.

## License

Configuration for personal use. Review and update all credentials and secrets before deploying.

---

**Home Lab**: Lenovo ThinkCentre (lemongrab) + Raspberry Pi 4 (pihole) · Linux (Debian-based) · [github.com/abracadaniel92/lenovo-homelab](https://github.com/abracadaniel92/lenovo-homelab)
