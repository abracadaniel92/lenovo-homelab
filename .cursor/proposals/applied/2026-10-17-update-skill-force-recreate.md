**Proposed change:** `.cursor/skills/update-homelab-service/SKILL.md`, step 7. After "This
recreates only the containers whose images changed." add: "Not always: if `up -d` says
`Running` and the version did not change, use `docker compose up -d --force-recreate --no-deps <service>`.
Check the version after, don't trust the `up` output."

**Why now:** The skill states something that was observed to be false.

**Evidence:** 2026-10-05 lemongrab log: nextcloud-app, `docker compose up -d app` said
"Running" and did NOT switch to the newly pulled image; `up -d --force-recreate --no-deps app`
did.

**Scope:** `.cursor/skills/update-homelab-service/SKILL.md`

**Boundaries:** One sentence plus one command in step 7. No change to the rest of the workflow.
