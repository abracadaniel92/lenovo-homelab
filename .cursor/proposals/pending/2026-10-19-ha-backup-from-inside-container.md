**Proposed change:** In `.cursor/skills/update-homelab-service/SKILL.md`, step 5, replace
"Home Assistant: tar its config dir to `/mnt/ssd/backups/homeassistant/ha-config-<version>-<date>.tar.gz`"
with "Home Assistant: `docker exec homeassistant tar czf - -C / config > /mnt/ssd/backups/homeassistant/ha-config-<version>-<date>.tar.gz`
(from inside the container: `config/.storage/` holds root-owned files a host-side tar can't read)."

**Why now:** A host-side tar as goce exited 2 with "Permission denied" on `.storage/auth`,
`core.config` and others, producing a 35 MB archive missing exactly the files a restore needs.

**Evidence:** 2026-10-19 on lemongrab, HA 2026.10.1 -> 2026.10.2. The in-container tar exited 0
and contained `.storage/auth` and `.storage/core.config`.

**Scope:** `update-homelab-service/SKILL.md` step 5, the Home Assistant line.

**Boundaries:** Does not add a `backup.d/` config for Home Assistant (that would be a separate decision).
