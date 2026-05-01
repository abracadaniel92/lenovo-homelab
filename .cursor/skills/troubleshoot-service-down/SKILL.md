---
name: troubleshoot-service-down
description: Diagnose and recover from homelab service outages — 502/404 errors, unreachable subdomains, Cloudflare tunnel issues, Caddy or Docker failures. Use when the user says "X is down", "subdomain returns 502", "tunnel not routing", "service unreachable", "site not loading externally", or otherwise reports a homelab service failure.
---

# Troubleshoot Service Down

Systematic diagnostic flow for homelab outages. Stay surgical: only touch the broken service. Do NOT modify unrelated services, the Caddyfile globals, or read-only infrastructure scripts (see governance rule).

## Surgical rule (MANDATORY)

- When troubleshooting "Service A", you are FORBIDDEN from editing the configuration of "Service B".
- Read-only: `scripts/enhanced-health-check.sh`, `scripts/fix-external-access.sh`, `scripts/backup-retention-helper.sh`, `systemd/*.service`, `systemd/*.timer`.
- If a global change seems necessary (Caddy globals, tunnel ID), STOP and ASK the user.

## Diagnostic flow

Copy this checklist:

```
- [ ] 1. Run safety-net: ./scripts/verify-services.sh
- [ ] 2. Check prior incidents: search useful-files/TROUBLESHOOTING_LOG.md
- [ ] 3. Check Docker daemon + container state
- [ ] 4. Check Caddy specifically (most outages are here or tunnel)
- [ ] 5. Check Cloudflare Tunnel
- [ ] 6. If service-specific: check that one container's logs
- [ ] 7. Apply minimum-scope fix
- [ ] 8. Re-run verify-services.sh
- [ ] 9. Log to TROUBLESHOOTING_LOG.md if non-standard
```

## 1. Safety net first

```bash
./scripts/verify-services.sh
```

This reveals which subdomains are down and which are healthy. Use this to scope the problem.

## 2. Check prior incidents

Before suggesting a fix, search [TROUBLESHOOTING_LOG.md](../../../useful-files/TROUBLESHOOTING_LOG.md) for the symptom. Many outages have known fixes — do not reinvent them.

```bash
rg -i "<symptom keyword>" useful-files/TROUBLESHOOTING_LOG.md
```

## 3. Docker state

```bash
docker ps                                    # are containers up?
docker ps -a | grep <service>                # has it crashed?
docker logs --tail 100 <container>           # what does it say?
```

If Docker daemon itself is down:
```bash
sudo systemctl status docker
sudo systemctl start docker
```

## 4. Caddy (the choke point)

Caddy is critical — if it's down, ALL subdomains fail.

```bash
docker ps | grep caddy
docker logs --tail 100 caddy
curl -I http://localhost:8080
curl -H "Host: <subdomain>.gmojsoski.com" http://localhost:8080
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
```

Restart only Caddy (NOT a global "restart everything"):
```bash
cd docker/caddy && docker compose restart caddy
```

## 5. Cloudflare Tunnel

If services work locally but external curls fail, the tunnel is the suspect.

```bash
sudo systemctl status cloudflared.service
journalctl -u cloudflared.service -n 30 --no-pager
```

CRITICAL config check: `~/.cloudflared/config.yml` `service:` URL MUST be `http://localhost:8080`. If it has been changed to `127.0.0.1:8080` — that's the bug. Fix it back to `localhost`.

Restart the tunnel:
```bash
cd docker/cloudflared && docker compose restart
# OR if running as systemd:
sudo systemctl restart cloudflared.service
```

Wait 1–2 minutes for reconnection.

## 6. Service-specific check

For container-restart-only fixes:
```bash
docker restart <container-name>
```

For systemd services:
```bash
sudo systemctl restart <service-name>
```

Check the service's own logs in `docker/<service>/` for app-level errors before restarting blindly.

## 7. Last-resort recovery scripts

ONLY when multiple services are down (broad outage), and after the above didn't help:

```bash
bash "restart services/fix-all-services.sh"     # comprehensive
bash "restart services/fix-subdomains-down.sh"  # 502/404 broadly
bash "restart services/emergency-fix.sh"        # faster, less thorough
```

These are READ-ONLY in this skill — do not edit them.

## 8. Verification

After any fix:
```bash
./scripts/verify-services.sh
curl -I https://<subdomain>.gmojsoski.com
```

## 9. Log it (if non-standard)

If the fix involved anything beyond a clean container restart, log it via the `log-troubleshooting-entry` skill or directly to [TROUBLESHOOTING_LOG.md](../../../usefull%20files/TROUBLESHOOTING_LOG.md).

## Common fixes (high-confidence)

| Symptom | Likely cause | Fix |
|---|---|---|
| All subdomains 502/404 | Caddy or tunnel down | `docker restart caddy` then check cloudflared |
| Works locally, not externally | Tunnel disconnected | Restart cloudflared, wait 1-2 min |
| Intermittent connection drops | `127.0.0.1:8080` in tunnel config | Change back to `localhost:8080` |
| Mobile streaming broken on Jellyfin | `encode gzip` in Caddy | Remove gzip from that block |
| Service down after reboot | Startup race | `sudo bash scripts/permanent-auto-recovery.sh` |

## Reference

- Full recovery system overview: [MONITORING_AND_RECOVERY.md](../../../useful-files/MONITORING_AND_RECOVERY.md)
- Historical incidents: [TROUBLESHOOTING_LOG.md](../../../useful-files/TROUBLESHOOTING_LOG.md)
- Cloudflare-specific: [CLOUDFLARE_MONITORING.md](../../../useful-files/CLOUDFLARE_MONITORING.md)
- Health check status: [HEALTH_CHECK_STATUS.md](../../../useful-files/HEALTH_CHECK_STATUS.md)
