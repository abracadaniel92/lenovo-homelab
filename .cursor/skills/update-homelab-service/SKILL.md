---
name: update-homelab-service
description: Safely update a Docker-composed homelab service (pull new image, restart, verify) while preserving data and respecting the surgical-isolation rule. Use when the user says "update X", "upgrade Y", "pull new image for Z", "bump service to latest", or wants to refresh a single service. For broad multi-service refreshes, run `scripts/update-check.sh --print` to see what is behind, then update one service at a time.
---

# Update Homelab Service

Safe, surgical update workflow for a single Docker-composed service. Always target the **live** working directory, preserve persistent data, and verify after.

## Nothing auto-updates

Watchtower was removed on 2026-09-25 and nothing replaced it on purpose: every update is manual. `update-check.timer` pushes a weekly ntfy list of images whose tag has a newer build (`scripts/update-check.sh --print` shows it on demand). Take extra care when:

- The service has **state** that needs care (Vaultwarden, Nextcloud, Immich, Outline, Mattermost, Linkwarden, Paperless, Cal, etc.)
- The user explicitly asks to update one service
- A breaking-change major version bump is involved (read release notes first)
- The service is **infrastructure-critical** (Caddy, cloudflared, Pi-hole, Portainer) — these should never be auto-updated; always manual + immediate verification

The weekly check cannot tell a patch from a major jump (Jellyfin `:latest` moved 10.x → 12.x), and it never sees newer releases of pinned tags. Check release notes before every pull.

Docker Hub allows 100 anonymous requests per hour per IP, and each pull and each check counts. A big batch of updates hits `429 Too Many Requests`; it refills within the hour. `update-check.sh` spends about 30 of them per run, so run it once, not repeatedly, right before pulling. If a pull hits 429, wait for the refill or pull via `mirror.gcr.io`.

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
- [ ] 9. Log to docs/reference/troubleshooting-log.md if anything was non-routine
```

## 1. Confirm scope

Ask the user (if unspecified):
- Which service exactly? (`docker ps`; `docker/` also holds dirs for stacks that no longer run)
- Pin a version, or "latest"?
- Have they read the release notes for breaking changes? (Especially Immich, Nextcloud, Outline.)

## 2. Locate the LIVE compose directory

The repo at `~/Desktop/Cursor projects/Pi-version-control/docker/<service>/` may differ from where the service is actually running. Inspect the live container:

```bash
docker inspect <container-name> --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'
```

Common live locations on this homelab:
- `/home/docker-projects/<service>/` (about half; `/mnt/ssd/docker-projects` is a symlink to it)
- `/home/apps/nextcloud`
- the repo's `docker/<service>/` (caddy, cloudflared and a few others)

After updating a stack under `/home/docker-projects/`, run `scripts/mirror-live-compose.sh` so the repo copy matches.

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

Mounts must point at persistent storage paths (`/home/...`, `/mnt/ssd_1tb/...`, `/mnt/ssd/...`; never the unplugged `/mnt/storage`). Anything pointing at an anonymous volume or a temp path is a data-loss risk; STOP and surface to the user.

## 5. Back up first (stateful services)

Mandatory for: Vaultwarden, Nextcloud, Immich, Outline, Mattermost, Linkwarden, Paperless, TravelSync, Cal.

Use the `homelab-backup-restore` skill or directly:

```bash
bash scripts/backup-engine.sh <service>   # if a backup config exists in scripts/backup.d/
```

No backup config yet for these; use the snapshot already used for them:
- Immich: covered by its own 02:00 DB dump in `/mnt/ssd_1tb/immich-library/backups/`; for a major version also `pg_dumpall` first.
- Outline (and other Postgres apps): `docker exec <db> pg_dumpall -U <user> | gzip > /mnt/ssd/backups/<svc>/<svc>-db-<version>-<date>.sql.gz`
- Home Assistant: tar its config dir to `/mnt/ssd/backups/homeassistant/ha-config-<version>-<date>.tar.gz`

Any other service without a backup config: STOP and ask the user — should we add one (via `homelab-backup-restore`) before updating, or proceed with manual snapshot, or accept the risk?

For stateless services (clawdbot, freshrss frontend, kiwix readers, stirling-pdf, etc.) skip this step.

## 6. Pull the new image

From the LIVE directory identified in step 2:

```bash
cd <live-directory>
docker compose pull              # pulls new images for all services in this compose file
```

If it says `No service selected`, the compose file uses profiles: `docker compose --profile <name> pull <service>` and the same `--profile` on `up -d` (Home Assistant: `--profile utilities`).

If the compose file pins a tag (`image: app:1.2.3`), bump the tag in the file FIRST, then pull. Do NOT silently change a pinned tag without user confirmation.

## 7. Restart with new image

```bash
docker compose up -d
```

This recreates only the containers whose images changed. Not always: if `up -d` says `Running` and the version did not change, use `docker compose up -d --force-recreate --no-deps <service>`. Check the version after, don't trust the `up` output. Existing volumes and networks are preserved.

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
- Recovery system overview: [MONITORING_AND_RECOVERY.md](../../../docs/concepts/monitoring-and-recovery.md)
- Service-specific notes: `docker/<service>/README.md` (where present)
