# CLAUDE.md — rules for AI agents working on lenovo-homelab

**The constitution for this repo is `.cursor/rules/homelab-governance.mdc` —
read it before doing anything.** It defines the non-negotiables (networking,
sacred files, scope isolation, storage placement, confirmation-required
deletions). This file adds Claude Code specifics, corrects paths that have
drifted since the constitution was written, and gives you the map.

## FIRST: figure out which machine you're on

This repo is cloned in four places, and the rules differ. **Before your first
action in a session, run `hostname`** (Windows: `$env:COMPUTERNAME`), say which
machine you're on in your first reply, and apply that machine's rules below.
If the hostname matches none of them, say so and treat the session as
repo-only until the user tells you otherwise.

- **On `lemongrab` (the Lenovo server, Debian-based Linux):** this machine IS
  production. ~30 containers serve real users at `*.gmojsoski.com`. For
  containers and configs, repo edits do NOT change live behavior — runtime
  reads live paths (`~/.cloudflared/config.yml`, `/mnt/ssd/docker-projects/...`,
  `/usr/local/bin/...`). A live fix means: change the live path, restart the
  service, verify, THEN mirror into the repo. See the constitution's
  "production vs version control" section.
  **Exception since 2026-09-25: `scripts/` IS live.** See the next section.
- **On the Windows dev machine (`C:\Users\Admin\Desktop\Cursor\lenovo-homelab`):**
  everything you do is **repo/VCS-only by definition**. You cannot restart
  services, run `verify-services.sh`, or touch live configs from here. Say so
  explicitly when a change needs a follow-up step on the server to take effect.
- **On the Pi (`pihole`):** the checkout is also live for DNS. Unbound
  bind-mounts `pihole/docker/unbound/unbound.conf` from it, so a branch switch
  or pull that touches that folder needs
  `cd pihole/docker/unbound && docker compose up -d` afterwards. Never use
  `docker/uptime-kuma/` there (that is lemongrab's); the Pi's is
  `pihole/docker/uptime-kuma/`. Log in `pihole/troubleshooting-log.md`.
- **On the Terra (`cricket`):** follow `terra/README.md` "Start here"; never
  format or write into the offsite drive. Log in `terra/troubleshooting-log.md`.

## ⚠️ On lemongrab, `git checkout` and `git pull` are DEPLOYS

`/opt/homelab` is a **symlink to this working tree**. The systemd health check,
its `health.d/` modules, the backup cron and the failure notifier all execute
through it. So on the server:

- **The checked-out branch is production code.** Checking out an older branch
  silently reverts the live health check and backup scripts. This happened on
  2026-09-25: a `git checkout develop` (21 commits behind) reverted the
  freshly-repaired `backup-engine.sh` while the hourly timer was armed.
- **`git pull` deploys instantly**, with no restart and no confirmation step.
- **Keep the server tree on `main`.** Commit straight to `main` here and push
  at the end of the task; never check out another existing branch. Details:
  the `prepare-pull-request` skill.
- **Verify after any branch operation:**
  `grep -c SQLITE_TAR /opt/homelab/scripts/backup-engine.sh` (expect 1).

The symlink exists because the repo path contains a space
(`/home/goce/Desktop/Cursor projects/...`), which broke every unquoted caller at
once and killed health checks, backups and auto-recovery for eight months. Never
reintroduce a space-containing path into a unit file, cron line or script.
See `docs/reference/troubleshooting-log.md` entry 2026-09-25.

**`/usr/local/bin` scripts are symlinks too since 2026-10-08**
(`enhanced-health-check.sh`, `hdd-health-check.sh`, `sync-backups-to-b2.sh`,
`update-portfolio.sh` -> `/opt/homelab/scripts/`), set up by
`scripts/link-usr-local-bin.sh`. So they are live code as well; never
`sudo install` a copy over them again. Pre-symlink copies sit beside them as
`*.sh.old`.

## Skills that already exist (use them, don't improvise)

`.cursor/skills/` has step-by-step runbooks — follow the matching one:
`add-homelab-service`, `update-homelab-service`, `troubleshoot-service-down`,
`homelab-backup-restore`, `homelab-storage-migration`,
`log-troubleshooting-entry`, `prepare-pull-request`, `lesson-review`,
`blog-review`, `weekly-review`.
The human-readable master for additions is `SERVICE_ADDITION_CHECKLIST.md`.

## Paths that moved (fixed in the constitution on 2026-10-17)

1. **Troubleshooting logs**, one per device, newest entry at the top:
   lemongrab `docs/reference/troubleshooting-log.md`, Pi
   `pihole/troubleshooting-log.md`, Terra `terra/troubleshooting-log.md`.
   `useful-files/` is gone; do NOT recreate it.
2. **Caddy is split**: `docker/caddy/Caddyfile` is globals + import +
   catch-all only. New services get a `handle` block in the right
   `docker/caddy/config.d/NN-category.caddy` snippet.
3. **`/mnt/ssd_1tb` is a 1 TB WD laptop HDD**, not an SSD (historical name).
   `/mnt/ssd` is a plain folder on the root disk.

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
- Storage: always ASK where new data lives (NVMe `/home` vs `/mnt/ssd_1tb`).
  The old HDDs and the mergerfs `/mnt/storage` pool were unplugged on
  purpose (old, unreliable) as of 2026-09-26; don't use it. Root partition is 101 GB — keep it lean;
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

After editing the root `Caddyfile` that validate checks the OLD file (single-file
bind mount keeps the old inode). Validate a copy instead:
`docker cp docker/caddy/Caddyfile caddy:/tmp/Caddyfile.new && docker exec caddy caddy validate --config /tmp/Caddyfile.new --adapter caddyfile`,
then `docker restart caddy`. Edits under `config.d/` (a directory mount) are
seen normally.

New-route restart sequence: add the ingress line to the live
`~/.cloudflared/config.yml` (edit it; never `cp` the repo copy over it, they
differ) → restart caddy → restart cloudflared → verify. Caddy and cloudflared only read config at startup.

Commands the owner must run (`! <cmd>`): keep them to one short line, at most
two steps joined by `&&`; otherwise write a scratchpad script and give
`! bash <script>`. On the phone (Termius) long pasted lines wrap and each piece
runs as its own command; you can't tell which device is in use.

## Docs map

Everything is indexed in `docs/README.md` (diátaxis-style: concepts /
how-to-guides / reference). Key references: `port-map.md`,
`infrastructure-summary.md`, `common-commands.md`, `lab-commands.md`,
`lan-and-vpn-service-urls.md`. The incident log (`troubleshooting-log.md`)
is append-only and mandatory for production-affecting changes — read it
before diagnosing anything; your incident may already be documented.

## Known drift / open items (as of 2026-10-17)

- **`docker/caddy/site/` holds the OLD portfolio** (vanilla HTML/JS). The
  live site is now built from the separate `portfolio_v2` repo via
  `scripts/update-portfolio.sh` → synced to `/mnt/ssd/docker-projects/caddy/site`
  on the server. The repo's `site/` copy is stale by design of the new
  pipeline — don't edit it expecting to change gmojsoski.com.
- **There is no SSO.** The never-run Authelia stack, its repo mirror and the
  `auth.gmojsoski.com` Caddy block were removed 2026-10-18.
- Stacks under `/home/docker-projects/` and `/home/apps/nextcloud` run from
  those live paths. Their compose files are mirrored into `docker/<name>/` by
  `scripts/mirror-live-compose.sh` (live is truth; secrets stay in each live
  `.env`, never inline: the repo is PUBLIC). `gokapi/` and a few others still
  have no compose dir under `docker/`. Don't assume `docker/` is the
  complete service inventory; `docs/reference/infrastructure-summary.md` and
  the Caddy `config.d/` snippets are closer to truth.
- `docker/` still has dirs for stacks that no longer run: `beszel`,
  `scrutiny`, `ntfy` (rolled back 2026-07-28), `kitchenowl` (removed
  2026-07-28), `clawdbot`. `docker ps` is the truth for what runs.
- `scripts/backup-all-critical.sh` still lists `kitchenowl` in `SERVICES`.
- The `restart services/` directory has a space in its name — quote paths.

## Non-negotiable habits

1. Check the device's troubleshooting log before diagnosing.
2. After resolving anything production-affecting, add a dated entry there
   (symptom → change (live vs repo paths) → commands → verification →
   outcome). Never rewrite old entries.
3. `./scripts/verify-services.sh` after every network change.
4. Update `README.md` service table + `port-map.md` when adding a service.
5. **Small atomic commits, often.** Commit after each step that works: one
   logical change per commit, production changes together with their log
   entry, subject `<Area>: <outcome>; log <date>`. Commit locally as you go;
   push at the end of the task. Publishing depends on the machine: lemongrab
   commits on `main` directly, other machines use `feature/<date>-<name>` →
   PR into `main` (merge or rebase, never squash). `develop` is retired. Full
   rules: `prepare-pull-request` skill. Pre-commit runs YAML/shell checks;
   Renovate handles image bumps.
6. **Lesson capture** (`.cursor/rules/lesson-capture.mdc`): when a skill,
   rule or this file misled you, or the user corrects how you work, don't
   edit the guidance. Drop a proposal in `.cursor/proposals/pending/` and
   carry on; the user reviews them with the `lesson-review` skill.
7. **Blog capture** (`.cursor/rules/blog-capture.mdc`): when finished work
   makes a good story (hidden root cause, silent failure, before/after
   number, migration), write a candidate to `.cursor/blog/pending/` and end
   the reply with `Blog candidate: <title>`. The owner approves or rejects
   them with the `blog-review` skill.
8. **Weekly review**: "weekly review" runs the `weekly-review` skill
   (lessons, blog candidates, open items and reverse conditions).
