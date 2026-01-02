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

All backup scripts use the smart retention helper:
- `backup-vaultwarden.sh`
- `backup-nextcloud.sh`
- `backup-kitchenowl.sh`
- `backup-travelsync.sh`

Helper script: `scripts/backup-retention-helper.sh`

## Backup Locations

| Service | Local Path | Pattern |
|---------|-----------|---------|
| Vaultwarden | `/mnt/ssd/backups/vaultwarden/` | `vaultwarden-*.tar.gz` |
| Nextcloud | `/mnt/ssd/backups/nextcloud/` | `nextcloud-*.tar.gz` |
| KitchenOwl | `/mnt/ssd/backups/kitchenowl/` | `kitchenowl-*.db` |
| TravelSync | `/mnt/ssd/backups/travelsync/` | `travelsync-*.tar.gz` |

## Offsite Sync

Backups are automatically synced to Backblaze B2:
- **Tool**: rclone
- **Remote**: `b2-backup:Goce-Lenovo/`
- **Policy**: Mirrors local directory (same retention)
- **Excludes**: Problematic directories with permission issues

See also:
- [Backup Setup Guide](../how-to-guides/setup-backup.md)
- [Backup Options Comparison](CHEAPEST_BACKUP_OPTIONS.md)
- [Replication Strategy](REPLICATION_STRATEGY.md)

---

*Last updated: January 2026*

