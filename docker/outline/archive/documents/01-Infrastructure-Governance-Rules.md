# Infrastructure Governance Rules

This document defines the strict operating rules for the homelab infrastructure.

## 🔴 CRITICAL: Networking & Ingress (NEVER CHANGE)

### Cloudflare Tunnel Binding
- **RULE**: In `~/.cloudflared/config.yml`, the `service` URL must ALWAYS be `http://localhost:8080`
- **PROHIBITED**: NEVER use `127.0.0.1:8080`. This causes intermittent connection failures
- **WHY**: The tunnel runs in Docker with host networking; `localhost` resolves reliably via `/etc/hosts`, while `127.0.0.1` has caused loopback routing issues

### Caddy Reverse Proxy
- **Source of Truth**: `docker/caddy/Caddyfile` is the ONLY valid configuration file
- **Standard Block**: When adding a new service, use this EXACT template:
  ```
  handle @subdomain {
      reverse_proxy http://172.17.0.1:PORT
  }
  ```
- **NO Header Overrides**: DO NOT add `header_up Host {host}` or `X-Forwarded-*` unless explicitly required
- **Media Servers**: For Jellyfin/Plex/Navidrome, explicit `encode gzip` is PROHIBITED as it breaks mobile streaming

## 🛡️ Operational Safety

### Governance
- **NEVER** modify existing, working Caddyfile blocks while troubleshooting a new service
- **ALWAYS** check `usefull files/TROUBLESHOOTING_LOG.md` before suggesting a fix
- **ALWAYS** run `scripts/verify-services.sh` after any network change

### Service Addition Protocol
- Read `SERVICE_ADDITION_CHECKLIST.md` before generating config
- Check for port conflicts (`sudo ss -tulpn`) before assigning a port

## 🟢 Allowed Extensions (Append Only)

The following files are CRITICAL infrastructure. You may **ONLY** add new entries to them:
- `~/.cloudflared/config.yml`: Add new ingress rules to the list
- `docker/caddy/Caddyfile`: Add new `handle @service` blocks
- `scripts/verify-services.sh`: Add new domains to the `SUBDOMAINS` array
- `README.md`: Add new service descriptions

## 🔴 Read-Only (Core Infrastructure)

Never edit these files as part of a routine service addition:
- `scripts/enhanced-health-check.sh`
- `scripts/fix-external-access.sh`
- `scripts/backup-retention-helper.sh`
- All files in `systemd/*.service` or `systemd/*.timer`

## 🟡 Scope-Locked (Service Configs)

- `docker/<service>/docker-compose.yml` and `.env` files are **LOCKED** to that service
- You may edit a service's config ONLY if you are specifically troubleshooting that service
- **Forbidden**: Never edit `docker/jellyfin/...` when working on Paperless

