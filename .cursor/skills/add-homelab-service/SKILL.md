---
name: add-homelab-service
description: Add a new service to the homelab — Docker Compose, Caddy reverse proxy block, Cloudflare Tunnel ingress, verification, and README/log updates. Use when the user asks to "add a service", "expose X via Cloudflare", "set up a new subdomain", "publish X to gmojsoski.com", or otherwise wants a new service routed through the tunnel.
---

# Add Homelab Service

Canonical workflow for adding a new service to the Pi homelab. Follow it end-to-end. Do NOT take shortcuts (e.g. running long-lived host processes instead of Docker) unless the user explicitly asks for that.

## Workflow checklist

Copy this checklist and track progress as you go:

```
- [ ] 1. Confirm scope with user (port, storage, subdomain, stack)
- [ ] 2. Port allocation: check `sudo ss -tulpn` for conflicts (avoid 5000, 9000)
- [ ] 3. Create docker/<service>/docker-compose.yml with bridge network + restart: unless-stopped
- [ ] 4. Add @service block to docker/caddy/Caddyfile (append-only, standard template)
- [ ] 5. Add ingress rule to cloudflare/config.yml AND ~/.cloudflared/config.yml
- [ ] 6. Restart Caddy then cloudflared (in that order)
- [ ] 7. Triple-check verification (internal, proxy, external)
- [ ] 8. Append the new domain to scripts/verify-services.sh SUBDOMAINS array
- [ ] 9. Add service description to README.md
- [ ] 10. Log a TROUBLESHOOTING_LOG.md entry only if anything non-standard happened
```

## 1. Confirm scope

Before writing any config, ask the user (if not specified):
- Subdomain name (e.g. `service.gmojsoski.com`)
- Internal port (preferred range 8000-8100)
- Where does the service's data live? — primary NVMe vs `/mnt/ssd_1tb` vs mergerfs `/mnt/storage`. NEVER assume.
- Is this a media server (Jellyfin/Plex/Navidrome class)? If yes, skip gzip in Caddy.

## 2. Port allocation

```bash
sudo ss -tulpn | grep :<PORT>
```

Avoid: `5000` (AirPlay), `9000` (Portainer). Preferred range: `8000-8100`.

## 3. Docker Compose

Create `docker/<service>/docker-compose.yml`. Defaults:
- **Network**: standard bridge — do NOT use `network_mode: host` unless absolutely necessary.
- **Volumes**: map data into the storage location agreed in step 1 (typically `/mnt/ssd/docker-projects/<service>/data` or wherever the user chose).
- **Restart**: `restart: unless-stopped`.

## 4. Caddy block

Append to `docker/caddy/Caddyfile`. Use this EXACT template — no header overrides unless docs explicitly require them:

```caddyfile
@service_name host service.gmojsoski.com
handle @service_name {
    reverse_proxy http://172.17.0.1:PORT
}
```

If the upstream app expects HTTPS signals from a proxy, ONLY then add:
```caddyfile
header_up X-Forwarded-Proto https
header_up X-Forwarded-Ssl on
```

For media servers, do NOT add `encode gzip` — it breaks mobile streaming.

Validate before restart:
```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

## 5. Cloudflare Tunnel ingress

Add the new ingress rule to BOTH `cloudflare/config.yml` (repo) and `~/.cloudflared/config.yml`. The `service` URL must ALWAYS be `http://localhost:8080` — NEVER `127.0.0.1:8080`.

```yaml
- hostname: service.gmojsoski.com
  service: http://localhost:8080
```

Do NOT change the `tunnel` ID or credentials file. Do NOT modify existing rules.

## 6. Restart sequence

Required — Caddy and cloudflared only read config at startup:

```bash
cp cloudflare/config.yml ~/.cloudflared/config.yml
cd docker/caddy && docker compose restart caddy
cd ../cloudflared && docker compose restart
```

## 7. Triple-check verification

```bash
curl -I http://localhost:PORT                                     # internal
curl -H "Host: service.gmojsoski.com" http://localhost:8080       # caddy
curl -I https://service.gmojsoski.com                             # external (cloudflare)
```

Mobile check: disable Wi-Fi on phone, confirm the site loads.

Then run the safety net:
```bash
./scripts/verify-services.sh
```

## 8. Update verify-services.sh

Append the new subdomain to the `SUBDOMAINS` array in `scripts/verify-services.sh`. Append-only — do NOT modify existing entries.

## 9. Update README.md

Add a description of the new service (what it does, port, subdomain) to the appropriate section.

## 10. Log only if needed

Standard, smooth additions do NOT need a `TROUBLESHOOTING_LOG.md` entry. Only log if:
- Something broke during the addition
- A non-standard fix was applied
- Lessons were learned worth keeping

If logging, follow the format in the `log-troubleshooting-entry` skill.

## Rollback (if it breaks things)

1. Delete the lines you added to `Caddyfile` and `~/.cloudflared/config.yml`.
2. `docker compose restart caddy`
3. `./restart\ services/fix-external-access.sh`
4. `./scripts/verify-services.sh` to confirm green.

## Reference

For the full long-form checklist, see [SERVICE_ADDITION_CHECKLIST.md](../../../SERVICE_ADDITION_CHECKLIST.md).
