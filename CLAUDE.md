# CLAUDE.md — rules for AI agents working on lenovo-homelab

**The constitution for this repo is `.cursor/rules/homelab-governance.mdc` —
read it before doing anything.** It defines the non-negotiables (networking,
sacred files, scope isolation, storage placement, confirmation-required
deletions). This file adds Claude Code specifics, corrects paths that have
drifted since the constitution was written, and gives you the map.

## FIRST: figure out which machine you're on

This repo is cloned in two places, and the rules differ:

- **On `lemongrab` (the Lenovo server, Debian-based Linux):** this machine IS
  production. ~30 containers serve real users at `*.gmojsoski.com`. Repo edits
  do NOT change live behavior — runtime reads live paths
  (`~/.cloudflared/config.yml`, `/mnt/ssd/docker-projects/...`,
  `/usr/local/bin/...`). A live fix means: change the live path, restart the
  service, verify, THEN mirror into the repo. See the constitution's
  "production vs version control" section.
- **On the Windows dev machine (`C:\Users\Admin\Desktop\Cursor\lenovo-homelab`):**
  everything you do is **repo/VCS-only by definition**. You cannot restart
  services, run `verify-services.sh`, or touch live configs from here. Say so
  explicitly when a change needs a follow-up step on the server to take effect.

## Skills that already exist (use them, don't improvise)

`.cursor/skills/` has step-by-step runbooks — follow the matching one:
`add-homelab-service`, `update-homelab-service`, `troubleshoot-service-down`,
`homelab-backup-restore`, `homelab-storage-migration`,
`log-troubleshooting-entry`, `prepare-pull-request`.
The human-readable master for additions is `SERVICE_ADDITION_CHECKLIST.md`.

## Path corrections (the constitution has drifted — trust THIS list)

1. **Troubleshooting log** is at `docs/reference/troubleshooting-log.md`
   (guidelines: `docs/reference/troubleshooting-log-guidelines.md`). The
   constitution still says `useful-files/TROUBLESHOOTING_LOG.md` — that
   directory no longer exists. Do NOT recreate `useful-files/`.
2. **Caddy config is now split**: `docker/caddy/Caddyfile` holds only globals
   + `import /etc/caddy/config.d/*.caddy` + the catch-all file server. Service
   routes live in `docker/caddy/config.d/` grouped by category
   (`10-gmojsoski-home`, `20-media`, `30-storage`, `40-communication`,
   `50-utilities`). New services get a `handle` block in the right category
   snippet — not in the root Caddyfile as the constitution/checklist still
   imply. The block template and "no header overrides / no gzip for media"
   rules are unchanged.

## Invariants (short form — full versions in the constitution)

- Cloudflare tunnel `service:` URLs are ALWAYS `http://localhost:8080`,
  never `127.0.0.1:8080`.
- Standard Caddy block: `handle @svc { reverse_proxy http://172.17.0.1:PORT }`.
- Append-only sacred files: `~/.cloudflared/config.yml` (+ repo
  `cloudflare/config.yml`), Caddy configs, `scripts/verify-services.sh`
  SUBDOMAINS, `README.md` service table. Add entries; never modify/delete
  existing ones without explicit permission.
- Read-only core: `scripts/enhanced-health-check.sh`,
  `scripts/fix-external-access.sh`, `scripts/backup-retention-helper.sh`,
  everything in `systemd/`.
- Scope isolation: troubleshooting service A never touches service B's files.
- Removing ANY public routing (Caddy block or tunnel hostname) requires an
  impact summary + explicit user confirmation first.
- Storage: always ASK where new data lives (NVMe `/home` vs `/mnt/ssd_1tb`
  vs mergerfs `/mnt/storage`). Root partition is 101 GB — keep it lean;
  never put service data on `/`.
- Ports: preferred range 8000–8100; check `sudo ss -tulpn` first; avoid
  5000 (AirPlay) and 9000 (Portainer). Authoritative list:
  `docs/reference/port-map.md`.

## Commands (on the server)

```bash
make            # = make health (enhanced health check)
make status     # docker ps overview
make logs service=<name>
make backup     # all critical backups
make fix        # emergency external-access recovery
make portfolio-update   # rebuild gmojsoski.com from portfolio_v2 + sync to Caddy
./scripts/verify-services.sh   # MANDATORY after any network change
docker exec caddy caddy validate --config /etc/caddy/Caddyfile  # before restarting Caddy
```

New-route restart sequence: copy tunnel config → restart caddy → restart
cloudflared → verify. Caddy and cloudflared only read config at startup.

## Docs map

Everything is indexed in `docs/README.md` (diátaxis-style: concepts /
how-to-guides / reference). Key references: `port-map.md`,
`infrastructure-summary.md`, `common-commands.md`, `lab-commands.md`,
`lan-and-vpn-service-urls.md`. The incident log (`troubleshooting-log.md`)
is append-only and mandatory for production-affecting changes — read it
before diagnosing anything; your incident may already be documented.

## Known drift / open items (as of 2026-07-06)

- **README service table lists removed services**: Actual Budget
  (budget.gmojsoski.com) and Centar Srbija Stil (css.gmojsoski.com) were
  removed from the stack (commit 88ace93) but still appear in `README.md`.
  The `css-update` Makefile target, `scripts/update-css.sh`, and
  `scripts/css-update` are likewise orphaned. Removing them needs the user's
  OK (README rows are append-only-protected).
- **`docker/caddy/site/` holds the OLD portfolio** (vanilla HTML/JS). The
  live site is now built from the separate `portfolio_v2` repo via
  `scripts/update-portfolio.sh` → synced to `/mnt/ssd/docker-projects/caddy/site`
  on the server. The repo's `site/` copy is stale by design of the new
  pipeline — don't edit it expecting to change gmojsoski.com.
- **Authentik** appears in `docs/reference/lan-and-vpn-service-urls.md`
  (`:9091`) but has no `docker/authentik/` stack in the repo — either it runs
  unversioned on the server or the doc is aspirational. Verify on the server
  before assuming SSO exists.
- `kitchenowl/`, `linkwarden/`, `gokapi/` and some others have backup
  scripts + Caddy routes but no compose dir under `docker/` — they run from
  live paths not fully mirrored in the repo. Don't assume `docker/` is the
  complete service inventory; `docs/reference/infrastructure-summary.md` and
  the Caddy `config.d/` snippets are closer to truth.
- The `restart services/` directory has a space in its name — quote paths.

## Non-negotiable habits

1. Check `docs/reference/troubleshooting-log.md` before diagnosing.
2. After resolving anything production-affecting, append a dated entry there
   (symptom → change (live vs repo paths) → commands → verification →
   outcome). Never rewrite old entries.
3. `./scripts/verify-services.sh` after every network change.
4. Update `README.md` service table + `port-map.md` when adding a service.
5. Branching: `feature/*` → `develop` → `main`. Pre-commit runs YAML/shell
   checks; Renovate handles image bumps.
