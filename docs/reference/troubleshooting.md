# Troubleshooting & Maintenance

Quick runbook for common issues and routine maintenance. For the chronological incident history, see [troubleshooting-log.md](troubleshooting-log.md) (and its [guidelines](troubleshooting-log-guidelines.md)). For whole-system recovery scripts and startup order, see [../concepts/monitoring-and-recovery.md](../concepts/monitoring-and-recovery.md).

## Troubleshooting

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
docker logs <container-name>
docker inspect <container-name> --format '{{.State.Health}}'
```

### Database locked errors

```bash
# Stop the container first
cd /home/docker-projects/<service>
docker compose stop
# Make changes, then restart
docker compose up -d
```

### Caddy routing issues

```bash
# Validate config (checks main Caddyfile + all split configs)
cd /home/docker-projects/caddy
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload config
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# View split config files
ls -la /home/docker-projects/caddy/config.d/

# Inspect a specific service config
cat /home/docker-projects/caddy/config.d/20-media.caddy
```

Structure: main `docker/caddy/Caddyfile` imports `docker/caddy/config.d/*.caddy` (service-specific). Isolated configs prevent cascading failures.

### Cloudflare Tunnel issues

```bash
# Status
docker ps --filter "name=cloudflared"

# Logs
docker logs cloudflared-cloudflared-1

# Restart
cd /home/docker-projects/cloudflared && docker compose restart

# Inspect ingress
grep -E "service|ingress" ~/.cloudflared/config.yml

# Manual fix: ensure all rules use localhost:8080 (not 127.0.0.1:8080)
sed -i 's/127.0.0.1:8080/localhost:8080/g' ~/.cloudflared/config.yml
```

The hourly health check auto-detects and fixes `127.0.0.1:8080` → `localhost:8080`, validates all ingress rules, and restarts the tunnel after fixes.

## Maintenance

### Update a Docker service

```bash
cd /home/docker-projects/<service>
docker compose pull
docker compose up -d
docker compose logs -f      # view logs
docker compose restart      # restart
```

### Watchtower auto-updates

Watchtower updates containers daily at 2 AM, **except** (manual updates only): Nextcloud, Vaultwarden, Jellyfin, KitchenOwl.

### Resource limits

Containers set `mem_limit`, `memswap_limit`, and `cpus` in their `docker-compose.yml`:

| Service | Memory | CPU |
|---------|--------|-----|
| Jellyfin | 8GB | 2.0 |
| Nextcloud (app) | 4GB | 1.0 |
| Nextcloud (db) | 2GB | 1.0 |
| Mattermost (app) | 4GB | 1.0 |
| Mattermost (db) | 2GB | 1.0 |
| Paperless (webserver) | 2GB | 1.0 |
| Paperless (broker) | 512MB | 0.5 |
| Home Assistant | 2GB | 1.0 |

### Check service status

```bash
docker ps                                    # all containers
systemctl status planning-poker bookmarks gokapi   # systemd services
curl -s -o /dev/null -w "%{http_code}\n" https://jellyfin.gmojsoski.com  # external access
```

## See also

- [Common commands](common-commands.md)
- [Lab command cheat sheet](lab-commands.md)
- [Health check status](health-check-status.md)
- [Cloudflare monitoring](../how-to-guides/cloudflare-monitoring.md)
