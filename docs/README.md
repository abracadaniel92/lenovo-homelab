# Documentation Index

All documentation for the homelab, organized [Diátaxis](https://diataxis.fr/)-style: **concepts** (understanding), **how-to guides** (tasks), and **reference** (lookup). The root [README](../README.md) is the orientation map; everything detailed lives here.

## Concepts (`concepts/`)

Architecture and design decisions:

- [monitoring-and-recovery.md](concepts/monitoring-and-recovery.md) — multi-layer monitoring & auto-recovery system
- [backup-strategy.md](concepts/backup-strategy.md) — backup architecture, retention tiers, verification
- [cheapest-backup-options.md](concepts/cheapest-backup-options.md) — comparison of backup storage options
- [replication-strategy.md](concepts/replication-strategy.md) — data replication & disaster recovery
- [secrets-management-plan.md](concepts/secrets-management-plan.md) — secrets management strategy

## How-to guides (`how-to-guides/`)

Step-by-step tasks:

- [setup.md](how-to-guides/setup.md) — end-to-end main-server setup (Docker, Caddy, services, profiles)
- [pi-hole-setup.md](how-to-guides/pi-hole-setup.md) — Raspberry Pi 4 DNS & ad blocking
- [mcp-knowledge-server.md](how-to-guides/mcp-knowledge-server.md) — private LAN knowledge MCP server (Cursor + Claude Code CLI)
- [cloudflare-monitoring.md](how-to-guides/cloudflare-monitoring.md) — where & how to monitor the Cloudflare Tunnel
- [setup-uptime-kuma-notifications.md](how-to-guides/setup-uptime-kuma-notifications.md) — Uptime Kuma alerts (ntfy.sh)
- [kitchenowl-recipe-import.md](how-to-guides/kitchenowl-recipe-import.md) — import .docx recipes into KitchenOwl
- [jellyfin-books-setup.md](how-to-guides/jellyfin-books-setup.md) — add a books library to Jellyfin
- [external-access-investigation.md](how-to-guides/external-access-investigation.md) — troubleshooting external access
- [test-docker-profiles.md](how-to-guides/test-docker-profiles.md) — verifying Docker Compose profiles

## Reference (`reference/`)

Quick lookup & technical detail:

- [infrastructure-diagram.md](reference/infrastructure-diagram.md) — full diagram: services, topology, monitoring
- [infrastructure-summary.md](reference/infrastructure-summary.md) — current infrastructure overview
- [port-map.md](reference/port-map.md) — single source of truth for host ports
- [common-commands.md](reference/common-commands.md) — frequently used commands
- [lab-commands.md](reference/lab-commands.md) — `lab-make` cheat sheet (Makefile shortcuts)
- [troubleshooting.md](reference/troubleshooting.md) — common-issue runbook & maintenance
- [troubleshooting-log.md](reference/troubleshooting-log.md) — chronological incident & change log
- [troubleshooting-log-guidelines.md](reference/troubleshooting-log-guidelines.md) — how/what to log
- [health-check-status.md](reference/health-check-status.md) — health check configuration status
- [lan-and-vpn-service-urls.md](reference/lan-and-vpn-service-urls.md) — LAN/VPN service URL cheat sheet
- [learnings-from-repos.md](reference/learnings-from-repos.md) — learnings from analyzing other repos

## Quick links

- **Setup**: [how-to-guides/setup.md](how-to-guides/setup.md)
- **Infrastructure diagram**: [reference/infrastructure-diagram.md](reference/infrastructure-diagram.md)
- **Port map**: [reference/port-map.md](reference/port-map.md)
- **Backups**: [concepts/backup-strategy.md](concepts/backup-strategy.md)
- **Troubleshooting**: [reference/troubleshooting.md](reference/troubleshooting.md)

---

Per-service deep docs live next to each stack as `docker/<service>/README.md`. Doc history is in git — no manual "last updated" stamps.
