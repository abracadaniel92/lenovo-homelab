---
name: update-homelab-service
description: Safely update a Docker-composed homelab service (pull new image, restart, verify) while preserving data and respecting the surgical-isolation rule. Use when the user says "update X", "upgrade Y", "pull new image for Z", "bump service to latest", or wants to refresh a single service. For broad multi-service refreshes, prefer Watchtower or ask the user explicitly.
---

# Update Homelab Service

Safe, surgical update workflow for a single Docker-composed service. Always target the **live** working directory, preserve persistent data, and verify after.

## When to use this skill vs Watchtower

The repo has `docker/watchtower/` running for opportunistic auto-updates. Use this skill instead when:

- The service has **state** that needs care (Vaultwarden, Nextcloud, Immich, Outline, KitchenOwl, Mattermost, Linkwarden, paperless, etc.)
- The user explicitly asks to update one service
- A breaking-change major version bump is involved (read release notes first)
- The service is **infrastructure-critical** (Caddy, cloudflared, Pi-hole, Portainer) — these should never be auto-updated; always manual + immediate verification

For low-risk stateless services already covered by Watchtower, just confirm with the user that they want a manual update before running this workflow.

## Workflow

```
- [ ] 1. Confirm scope: which service, current vs target version
- [ ] 2. Locate the LIVE compose directory (not the repo, if they differ)
- [ ] 3. Read service notes (docker/<service>/README.md, release notes)
- [ ] 4. Verify volume mounts point at persistent storage
- [ ] 5. Back up first (mandatory for stateful services)
- [ ] 6. docker compose pull
- [ ] 7. docker compose up -d
- [ ] 8. Verify health (container status + app endpoint + verify-services.sh)
- [ ] 9. Log to TROUBLESHOOTING_LOG.md if anything was non-routine
```

## 1. Confirm scope

Ask the user (if unspecified):
- Which service exactly? (one of the 28 in `docker/`)
- Pin a version, or "latest"?
- Have they read the release notes for breaking changes? (Especially Immich, Nextcloud, Outline.)

## 2. Locate the LIVE compose directory

The repo at `~/Desktop/Cursor projects/Pi-version-control/docker/<service>/` may differ from where the service is actually running. Inspect the live container:

```bash
docker inspect <container-name> --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'
```

Common live locations on this homelab:
- `~/Desktop/Cursor projects/Pi-version-control/docker/<service>/` (most services)
- `/home/docker-projects/<service>/` (legacy path for some)
- `/mnt/ssd/docker-projects/<service>/` (storage-tier-specific)

ALWAYS run `docker compose` commands from the live directory. Updating the repo copy alone does NOTHING — Compose reads `docker-compose.yml` from the cwd.

## 3. Read service-specific notes

```bash
ls docker/<service>/
cat docker/<service>/README.md 2>/dev/null
```

Many services have README/SETUP_GUIDE files with version-specific gotchas. Skim them. Also check the upstream release notes for the new image — look for breaking changes, mandatory database migrations, env var renames.

## 4. Verify volume mounts

```bash
docker inspect <container-name> --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'
```

Mounts must point at persistent storage paths (`/home/...`, `/mnt/ssd_1tb/...`, `/mnt/ssd/...`, `/mnt/storage/...`). Anything pointing at an anonymous volume or a temp path is a data-loss risk; STOP and surface to the user.

## 5. Back up first (stateful services)

Mandatory for: Vaultwarden, Nextcloud, Immich, Outline, KitchenOwl, Mattermost, Linkwarden, paperless, TravelSync, Mattermost.

Use the `homelab-backup-restore` skill or directly:

```bash
bash scripts/backup-engine.sh <service>   # if a backup config exists in scripts/backup.d/
```

If no backup config exists for the service: STOP and ask the user — should we add one (via `homelab-backup-restore`) before updating, or proceed with manual snapshot, or accept the risk?

For stateless services (clawdbot, freshrss frontend, kiwix readers, stirling-pdf, etc.) skip this step.

## 6. Pull the new image

From the LIVE directory identified in step 2:

```bash
cd <live-directory>
docker compose pull              # pulls new images for all services in this compose file
```

If the compose file pins a tag (`image: app:1.2.3`), bump the tag in the file FIRST, then pull. Do NOT silently change a pinned tag without user confirmation.

## 7. Restart with new image

```bash
docker compose up -d
```

This recreates only the containers whose images changed. Existing volumes and networks are preserved.

For services with a **dependent stack** (DB + app, or app + reverse-proxy sidecar): check `depends_on` in the compose file to confirm restart order is sane.

## 8. Verify

```bash
docker compose ps                          # all services Up?
docker compose logs --tail 100 <service>   # any errors?
curl -I http://localhost:<port>            # is the app responding?
```

If the service is publicly routed via Caddy + Cloudflare:

```bash
curl -I https://<service>.gmojsoski.com    # external check
./scripts/verify-services.sh               # safety net
```

For **media servers** (Jellyfin, Plex, Navidrome): test mobile streaming after the update — the gzip rule and HTTP/2 quirks have bitten this homelab before.

For **infrastructure** (Caddy, cloudflared): confirm ALL public subdomains still resolve before walking away. Restart sequence if needed:

```bash
cd docker/caddy && docker compose restart caddy
cd ../cloudflared && docker compose restart
```

## 9. Log if non-routine

Routine updates that just worked don't need a log entry. Use the `log-troubleshooting-entry` skill if:

- Major version bump with breaking changes
- Required env var or compose changes
- Anything broke during the update and was fixed
- Lessons learned worth keeping

## Hard rules

- NEVER run `docker compose down` followed by `up -d` on a stateful service unless the user explicitly asks — it briefly drops connections and is unnecessary for image updates.
- NEVER `docker volume rm` or `docker compose down -v` on a stateful service.
- NEVER update unrelated services in the same session (surgical rule from `homelab-governance.mdc`). One service per update workflow.
- For Caddy/cloudflared/Pi-hole: **always** verify external connectivity within 2 minutes of restart. If anything is broken, run `restart services/fix-external-access.sh`.
- If the new version requires a one-off database migration, run it explicitly and watch logs — don't assume `up -d` handles it silently.

## Reference

- Backup workflow: `homelab-backup-restore` skill
- Post-update troubleshooting: `troubleshoot-service-down` skill
- Recovery system overview: [MONITORING_AND_RECOVERY.md](../../../useful-files/MONITORING_AND_RECOVERY.md)
- Service-specific notes: `docker/<service>/README.md` (where present)
