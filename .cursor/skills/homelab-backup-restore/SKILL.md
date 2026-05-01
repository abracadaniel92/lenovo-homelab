---
name: homelab-backup-restore
description: Run, configure, verify, or restore homelab backups for services like Vaultwarden, Nextcloud, KitchenOwl, TravelSync, Linkwarden, plus Backblaze B2 offsite sync. Use when the user says "back up X", "restore from B2", "verify backups are working", "set up backup cron for new service", "add a backup config", or otherwise wants to operate the backup system.
---

# Homelab Backup & Restore

The homelab uses a **unified backup engine** driven by per-service config files. Do not write one-off backup scripts — extend the engine instead.

## Architecture

```
scripts/
├── backup-engine.sh              # generic engine, takes a service name arg
├── backup-all-critical.sh        # wrapper: runs all critical services
├── backup-retention-helper.sh    # smart retention (READ-ONLY)
├── backup.d/
│   ├── kitchenowl.conf
│   ├── linkwarden.conf
│   ├── nextcloud.conf
│   ├── travelsync.conf
│   └── vaultwarden.conf
├── verify-backups.sh             # safety net for backup health
├── setup-backblaze-b2-backup.sh  # configure B2 offsite
├── sync-backups-to-b2.sh         # push local backups to B2
└── setup-all-backups-cron.sh     # install daily 02:00 cron
```

Backups land in `/mnt/ssd/backups/<service>/`. Daily cron runs at 02:00 via `/etc/crontab`. Retention: last 30 backups per service.

## Workflows

### Run a backup now (single service)

```bash
bash scripts/backup-engine.sh <service>
# e.g.
bash scripts/backup-engine.sh vaultwarden
```

### Back up everything critical

```bash
bash scripts/backup-all-critical.sh
```

### Verify backups are healthy

```bash
bash scripts/verify-backups.sh
```

Run this after any backup change, after restore tests, and proactively if it has been a while.

### Add backup support for a NEW service

```
- [ ] 1. Confirm service deserves backup (data persistence required)
- [ ] 2. Create scripts/backup.d/<service>.conf modeled on an existing one
- [ ] 3. Test: bash scripts/backup-engine.sh <service>
- [ ] 4. Add the service name to the SERVICES array in backup-all-critical.sh
- [ ] 5. Run scripts/verify-backups.sh
- [ ] 6. Update README.md backup section
- [ ] 7. (Optional) re-run scripts/setup-all-backups-cron.sh if cron needs refresh
```

Choose the right `TYPE` in the conf file:
- `DOCKER_TAR` — stop container, tar a data dir, restart container (Vaultwarden pattern)
- `PG_DUMP_AND_TAR` — pg_dump + tar of config (Nextcloud/Linkwarden pattern)
- `TAR` — tar a directory live (no DB)
- `TAR_DIR` — tar specific subdirs of a parent
- `FILE` — single-file copy

### Restore from a local backup

Use the service-specific restore script if one exists (e.g. `restore-kitchenowl.sh`). Otherwise:

1. Stop the container: `cd docker/<service> && docker compose stop`
2. Move existing data aside (do NOT delete until restore is verified): `mv data data.preserve.<date>`
3. Extract: `tar -xzf /mnt/ssd/backups/<service>/<file>.tar.gz -C <data target>`
4. Restart: `docker compose start`
5. Verify the service comes up clean and the data is intact.
6. Only then delete `data.preserve.<date>`.

### Backblaze B2 offsite

Initial setup (once):
```bash
bash scripts/setup-backblaze-b2-backup.sh
```

Routine sync (push local `/mnt/ssd/backups/` to B2):
```bash
bash scripts/sync-backups-to-b2.sh
```

To restore from B2: pull the desired archive locally first using the B2 CLI, then follow the local-restore procedure above.

### Cron maintenance

To (re)install the daily backup cron:
```bash
bash scripts/setup-all-backups-cron.sh
```

For a single service:
```bash
bash scripts/setup-kitchenowl-backup-cron.sh
```

## Hard rules

- `scripts/backup-retention-helper.sh` is **READ-ONLY** per governance. Don't edit it as part of a backup task.
- Always RUN `verify-backups.sh` after any change to `backup.d/*.conf` or the engine.
- Never delete a `data.preserve.*` directory until restore is verified.
- B2 credentials live in environment / `.env` files — never commit them.

## Reference

- Daily cron schedule and service list: see [MONITORING_AND_RECOVERY.md "Backup System" section](../../../usefull%20files/MONITORING_AND_RECOVERY.md).
- For a non-trivial restore or recovery, log it via the `log-troubleshooting-entry` skill afterwards.
