**Proposed change:** `.cursor/skills/update-homelab-service/SKILL.md`, step 6, after the
`docker compose pull` block. Add: "If it says `No service selected`, the compose file uses
profiles: `docker compose --profile <name> pull <service>` and the same `--profile` on
`up -d` (Home Assistant: `--profile utilities`)."

**Why now:** Worked out by trial during an update; one line saves the next session that step.

**Evidence:** 2026-10-05 lemongrab log, Home Assistant 2026.9.3 -> 2026.9.4: plain
`docker compose pull` said "No service selected".

**Scope:** `.cursor/skills/update-homelab-service/SKILL.md`

**Boundaries:** One note in step 6. Does not list every profile in every stack.
