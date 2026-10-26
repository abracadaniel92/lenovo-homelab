# Lesson decisions log

One line per decision made during `lesson-review`. Newest first. Check this before writing a
new proposal in `pending/`; never repeat an idea that was already rejected here without new
evidence.

| Date | Outcome | File changed | What changed, or why rejected |
|------|---------|---------------|-------------------------------|
| 2026-10-21 | Applied | `update-homelab-service/SKILL.md` | Step 6: read the pulled image's version before `up -d`; a new major means read its upgrade notes first. |
| 2026-10-21 | Applied | `update-homelab-service/SKILL.md` | Docker Hub paragraph: a `mirror.gcr.io` pull must be re-tagged to the plain name or Compose keeps the old image. |
| 2026-10-21 | Applied | `update-homelab-service/SKILL.md` | Step 5: back up Home Assistant with tar inside the container; host tar misses root-owned `.storage/` files. |
| 2026-10-18 | Applied | `CLAUDE.md` | Pi bullet names the real hostname `goce` (was `pihole`), so the `hostname` check matches. |
| 2026-10-18 | Applied | `blog-review/SKILL.md` | Step 1: grep portfolio_v2 published posts and drafts for overlap before asking |
| 2026-10-18 | Applied | `CLAUDE.md` | Commands the owner must run stay one short line (Termius on the phone wraps long ones) |
| 2026-10-17 | Applied | `update-homelab-service/SKILL.md` | Step 7: `up -d` can leave the old image running; use `--force-recreate --no-deps` and check the version. |
| 2026-10-17 | Applied | `update-homelab-service/SKILL.md` | Docker Hub paragraph: `update-check.sh` uses ~30 requests per run, run it once before pulling; `mirror.gcr.io` as the 429 fallback. |
| 2026-10-17 | Applied | `update-homelab-service/SKILL.md` | Step 6 note: "No service selected" means compose profiles; use `--profile <name>` on pull and up (HA: `utilities`). |
| 2026-10-17 | Applied | `update-homelab-service/SKILL.md` | Step 5 lists the manual snapshots for Immich, Outline/Postgres apps and Home Assistant; "ask" kept for other services without a backup config. |
| 2026-10-17 | Applied | `CLAUDE.md` | Machine section: four clones, run `hostname` first and name the machine in the first reply (owner's addition); Pi and Terra bullets. |
| 2026-10-17 | Applied | `CLAUDE.md` | Note under the Caddy validate command: after editing the root Caddyfile it checks the old file; validate a `docker cp` copy instead. `config.d/` edits are fine. |
