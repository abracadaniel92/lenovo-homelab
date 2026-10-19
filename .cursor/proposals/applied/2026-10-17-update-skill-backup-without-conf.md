**Proposed change:** `.cursor/skills/update-homelab-service/SKILL.md`, step 5. Replace "If no
backup config exists for the service: STOP and ask the user..." with the snapshots already used
for the services that have no `backup.d` conf, and keep "ask" only for anything else:
- Immich: covered by its own 02:00 DB dump in `/mnt/ssd_1tb/immich-library/backups/`; for a
  major version also `pg_dumpall` first.
- Outline (and other Postgres apps): `docker exec <db> pg_dumpall -U <user> | gzip >
  /mnt/ssd/backups/<svc>/<svc>-db-<version>-<date>.sql.gz`.
- Home Assistant: tar of its config dir to
  `/mnt/ssd/backups/homeassistant/ha-config-<version>-<date>.tar.gz`.

**Why now:** Every update session re-asks the same question and then does the same thing.

**Evidence:** 2026-10-05, 2026-10-12 and 2026-10-13 lemongrab log entries: manual `pg_dumpall`
for Immich and Outline and a config tar for HA, each noting "no backup.d conf exists".

**Scope:** `.cursor/skills/update-homelab-service/SKILL.md`

**Boundaries:** Documents the current manual snapshots only. Does not add `backup.d` confs for
these services (that is a separate homelab decision).
