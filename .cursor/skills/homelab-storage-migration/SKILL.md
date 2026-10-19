---
name: homelab-storage-migration
description: Migrate service data between storage tiers, format new disks, and decide where new data should live on lemongrab (NVMe /home, /mnt/ssd_1tb). Use when the user says "move X to ssd_1tb", "format the new disk", "where should this data go", "set up storage for new service", or otherwise touches disk layout.
---

# Homelab Storage Migration

This is a **low-freedom, scripted** workflow. Storage operations are destructive and recovery is painful — prefer the existing scripts over hand-rolled `rsync`/`mkfs` invocations.

## Storage tiers (recap)

Per the governance rule:

| Tier | Mount | Use for |
|---|---|---|
| Primary | NVMe `/home` (368 GB) | Docker data root, apps, databases |
| Primary | `/mnt/ssd_1tb` (1 TB **WD laptop HDD**, WD10SPZX; the name is historical) | Immich library, Kiwix, Pi backups |
| Keep lean | NVMe `/` (101 GB) | OS only. `/mnt/ssd` is a folder here; `/mnt/ssd/backups` really is on root |

There is no bulk tier any more: the USB HDDs and mergerfs `/mnt/storage` were unplugged on
2026-09-26. Redundancy comes from backups instead: B2 (nightly, rclone crypt) and the Terra
(restic over WireGuard; see `terra/README.md`).

## MANDATORY: Always ask first

When adding or relocating storage for a service or dataset, ALWAYS ask the user where it should live. Do NOT assume. Frame it like:

> "For `<service>`'s `<dataset>`, should it live on:
> - NVMe (`/home/...`)
> - the 1 TB HDD (`/mnt/ssd_1tb/...`)
> - and does it need a backup config (`scripts/backup.d/`)?"

Only proceed once the user confirms.

## Workflows

### Format a new disk (DESTRUCTIVE)

Use the canonical script. It wipes, partitions GPT, formats ext4, runs SMART:

```bash
sudo bash scripts/format-and-healthcheck-1tb-ssd.sh [/dev/sdX]
```

The script prints the UUID and the exact `/etc/fstab` line to add. After running:

```bash
echo "UUID=<uuid>  /mnt/ssd_1tb  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo mkdir -p /mnt/ssd_1tb
sudo mount /mnt/ssd_1tb
```

Verify with `lsblk`, `df -h`, and `findmnt /mnt/ssd_1tb`.

Always use `nofail`: on 2026-03-27 a missing USB disk hung boot (see the troubleshooting log).

For a spinning disk that runs 24/7, stop head parking with `scripts/fix-hdd-head-parking.sh`
(APM 254, persisted in `/etc/hdparm.conf`); see log entry 2026-10-17.

### Migrate Immich (canonical pattern)

```bash
sudo bash scripts/migrate-immich-to-ssd1tb.sh [OLD_LOCATION] [NEW_LOCATION]
```

This script is the template for any "move a service's data dir to a new mount" operation. It:

1. Verifies destination mount is mounted.
2. Stops the service containers (keeps DB/Redis running for state).
3. `rsync -av` from old → new (or seeds an empty structure).
4. Updates the service `.env` (`UPLOAD_LOCATION` etc.).
5. Restarts the service.
6. Leaves old data in place until the user confirms.

### Migrate a different service

Adapt the Immich script — do NOT improvise. Copy it to a new file under `scripts/migrate-<service>-to-<target>.sh`, then:

```
- [ ] 1. Confirm with user: source path, destination path, which containers to stop
- [ ] 2. Verify destination is mounted (mountpoint -q)
- [ ] 3. Stop service containers (keep DB/state services running)
- [ ] 4. rsync -av --progress SRC/ DST/
- [ ] 5. Update docker/<service>/.env or compose volume mounts
- [ ] 6. Restart service: docker compose up -d
- [ ] 7. Verify the service works AND the data is intact
- [ ] 8. Leave the old data in place until user confirms (do NOT auto-delete)
- [ ] 9. Log to docs/reference/troubleshooting-log.md (this is non-standard work)
```

### Set up storage for a brand-new service

1. Ask the user where the data should live (the question above).
2. Create the directory: `sudo mkdir -p <chosen path>` and chown to the appropriate user.
3. Reference that path in `docker/<service>/docker-compose.yml` volume mounts.
4. If the data matters, add a backup config (use the `homelab-backup-restore` skill). Anything under `/mnt/ssd/backups` goes to B2 automatically.

## Hard rules

- NEVER auto-delete old data after a migration. The user removes it manually after they confirm everything works.
- NEVER format a disk without explicit user confirmation (the script already prompts; don't pipe `yes` into it).
- ALWAYS run with `set -e` semantics — if a step fails, stop, do not continue.
- After any storage change, verify with `df -h`, `findmnt`, and the relevant service's UI.
- If the migration touched a service that has backups, run `bash scripts/verify-backups.sh` afterwards.

## Reference

- Storage policy: see governance rule (`homelab-governance.mdc`, sections 10-12).
- Generic file/data preference: `~/Desktop/Cursor projects/.cursor/rules/storage-preference.mdc` (workspace-level: prefer `/home` over `/`).
