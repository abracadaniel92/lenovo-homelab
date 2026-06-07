# Backup Strategy

Overview of the backup architecture and retention policies.

## Architecture

### Local Backups
- **Location**: `/mnt/ssd/backups/`
- **Schedule**: Daily at 2:00 AM
- **Services**: Vaultwarden, Nextcloud, KitchenOwl, TravelSync

### Offsite Backups (Backblaze B2)
- **Provider**: Backblaze B2 Cloud Storage
- **Bucket**: `Goce-Lenovo`
- **Sync Schedule**: Daily at 3:00 AM (after local backups)
- **Sync Script**: `/usr/local/bin/sync-backups-to-b2.sh`

## Retention Policy

### Multi-Tier Retention (Implemented)

All backup scripts use smart retention with the following policy:

| Tier | Retention | Description |
|------|-----------|-------------|
| **Hourly** | Last 6 backups | Backups within 6 hours |
| **Daily** | Last 5 backups | One backup per day (within 5 days) |
| **Weekly** | Last 4 backups | One backup per week (within 4 weeks) |
| **Monthly** | Last 2 backups | One backup per month (within 2 months) |
| **Yearly** | Last 1 backup | One backup per year (within 1 year) |

**Total backups kept**: Typically 18 backups (6+5+4+2+1), but can vary based on backup frequency.

### Benefits

- ✅ Better long-term recovery options
- ✅ Space-efficient (fewer total backups than flat 30-day retention)
- ✅ Automatic tier management
- ✅ Easy to recover from different time periods

## Backup Scripts

All backup scripts use the smart retention helper (`scripts/backup-retention-helper.sh`):
- `backup-vaultwarden.sh`
- `backup-nextcloud.sh`
- `backup-kitchenowl.sh`
- `backup-travelsync.sh`
- `backup-linkwarden.sh`

```bash
# Run all critical backups
bash scripts/backup-all-critical.sh

# Or individually
bash scripts/backup-vaultwarden.sh
bash scripts/backup-nextcloud.sh
bash scripts/backup-kitchenowl.sh
bash scripts/backup-travelsync.sh
bash scripts/backup-linkwarden.sh
```

## Backup Locations

| Service | Local Path | Importance |
|---------|-----------|------------|
| Vaultwarden | `/mnt/ssd/backups/vaultwarden/` | CRITICAL |
| Nextcloud | `/mnt/ssd/backups/nextcloud/` | High |
| Paperless | Docker volumes (data, media) | High |
| KitchenOwl | `/mnt/ssd/backups/kitchenowl/` | Medium |
| TravelSync | `/mnt/ssd/backups/travelsync/` | Medium |
| Linkwarden | `/mnt/ssd/backups/linkwarden/` | Medium |

## Verification

Backup integrity is verified **hourly** by the health check (`scripts/verify-backups.sh`): it checks `tar.gz` extractability, file sizes, backup age, and missing backups, and alerts Mattermost on problems.

```bash
# Run verification manually
bash scripts/verify-backups.sh

# View the verification log
tail -f ~/backup-verification.log
```

**Max-age thresholds** (verification alerts if exceeded):

| Service | Max age |
|---------|---------|
| Vaultwarden (CRITICAL) | 48h |
| Nextcloud (CRITICAL) | 48h |
| TravelSync (IMPORTANT) | 72h |
| KitchenOwl (IMPORTANT) | 72h |
| Linkwarden (MEDIUM) | 96h |

## Offsite Sync

Backups are automatically synced to Backblaze B2:
- **Tool**: rclone
- **Remote**: `b2-backup:Goce-Lenovo/`
- **Policy**: Mirrors local directory (same retention)
- **Excludes**: Problematic directories with permission issues

See also:
- [Backup Options Comparison](cheapest-backup-options.md)
- [Replication Strategy](replication-strategy.md)
- [Setup Instructions](../how-to-guides/setup.md)
