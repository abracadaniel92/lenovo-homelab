---
name: homelab-backup-restore
description: Run, configure, verify, or restore homelab backups for services like Vaultwarden, Nextcloud, TravelSync, Linkwarden, the Pi's nightly backup, plus the B2 and Terra offsite copies. Use when the user says "back up X", "restore from B2", "verify backups are working", "set up backup cron for new service", "add a backup config", or otherwise wants to operate the backup system.
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
│   ├── linkwarden.conf / nextcloud.conf / travelsync.conf / vaultwarden.conf
│   ├── kitchenowl.conf           # service removed 2026-07-28, conf still present
│   └── pi.conf                   # freshness check only; the Pi pushes its own archive
├── verify-backups.sh             # safety net for backup health
├── restore-drill.sh              # prove a backup restores
├── sync-backups-to-b2.sh         # nightly rclone-crypt push to B2 (sync-backups-to-b2.timer, 03:00)
├── backup-immich-terra.sh        # restic: Immich library + /mnt/ssd/backups to the Terra
└── setup-all-backups-cron.sh     # install daily 02:00 cron
```

Backups land in `/mnt/ssd/backups/<service>/` (on the root disk; keep it small). Daily cron runs at 02:00 via `/etc/crontab`. Retention: last 30 backups per service.

Monitoring: the hourly health check (`health.d/50-backup-freshness.sh`, `60-offsite-freshness.sh`) pushes to ntfy if a backup or the B2 copy goes stale.

Three copies of what matters: lemongrab, Backblaze B2 (all of `/mnt/ssd/backups`, follows symlinks so the Pi's backups on `/mnt/ssd_1tb/backups/pi` go too), and the Terra (Immich + `/mnt/ssd/backups`, but symlinks stay symlinks, so no Pi backups there).

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

Use the service-specific restore script if one exists (`scripts/restore-*.sh`); `scripts/restore-drill.sh` shows the tested path. Otherwise:

1. Stop the container: `cd docker/<service> && docker compose stop`
2. Move existing data aside (do NOT delete until restore is verified): `mv data data.preserve.<date>`
3. Extract: `tar -xzf /mnt/ssd/backups/<service>/<file>.tar.gz -C <data target>`
4. Restart: `docker compose start`
5. Verify the service comes up clean and the data is intact.
6. Only then delete `data.preserve.<date>`.

### Backblaze B2 offsite

Runs nightly from `sync-backups-to-b2.timer`; encrypted with rclone crypt (setup: `scripts/setup-b2-encrypted-sync.sh`). Manual run:
```bash
sudo systemctl start sync-backups-to-b2.service
```

To restore from B2: `rclone copy` the archive from the crypt remote to a local dir, then follow the local-restore procedure above. See log entry 2026-09-26 "B2 offsite".

### Terra offsite (restic)

See `terra/README.md` (Part B for the lemongrab side). The restic password is only on lemongrab (`/root/.config/restic/`, copy in Vaultwarden).

### Cron maintenance

To (re)install the daily backup cron:
```bash
bash scripts/setup-all-backups-cron.sh
```


## Hard rules

- `scripts/backup-retention-helper.sh` is **READ-ONLY** per governance. Don't edit it as part of a backup task.
- Always RUN `verify-backups.sh` after any change to `backup.d/*.conf` or the engine.
- Never delete a `data.preserve.*` directory until restore is verified.
- B2 credentials live in environment / `.env` files — never commit them.

## Reference

- Daily cron schedule and service list: see [MONITORING_AND_RECOVERY.md "Backup System" section](../../../docs/concepts/monitoring-and-recovery.md).
- For a non-trivial restore or recovery, log it via the `log-troubleshooting-entry` skill afterwards.
