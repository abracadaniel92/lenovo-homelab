# Complete Backup Setup Guide

## ✅ All Critical Services Now Have Backup Scripts

### 🔴 CRITICAL Services (Must Backup)

1. **Vaultwarden** - Password Vault
   - **Script:** `backup-vaultwarden.sh`
   - **Location:** `/mnt/ssd/backups/vaultwarden/`
   - **What it backs up:** Database, encryption keys, config
   - **⚠️ CRITICAL:** Losing this = losing all passwords!

2. **Nextcloud** - User Files & Database
   - **Script:** `backup-nextcloud.sh`
   - **Location:** `/mnt/ssd/backups/nextcloud/`
   - **What it backs up:** PostgreSQL database, config files
   - **Note:** User files are in `/mnt/ssd/apps/nextcloud/app/data/` (consider separate backup)

### 🟡 IMPORTANT Services

3. **TravelSync** - Travel Data & Calendar Events
   - **Script:** `backup-travelsync.sh`
   - **Location:** `/mnt/ssd/backups/travelsync/`
   - **What it backs up:** Database with travel documents and calendar events

4. **KitchenOwl** - Shopping Lists
   - **Script:** `backup-kitchenowl.sh` ✅
   - **Location:** `/mnt/ssd/backups/kitchenowl/`
   - **What it backs up:** Shopping lists database

## 🚀 Quick Commands

### Manual Backups

**Backup all critical services at once:**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-all-critical.sh"
```

**Backup individual services:**
```bash
# Vaultwarden (CRITICAL)
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-vaultwarden.sh"

# Nextcloud
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-nextcloud.sh"

# TravelSync
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-travelsync.sh"

# KitchenOwl
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-kitchenowl.sh"
```

### Automated Backups

**Setup automated daily backups (one-time, requires sudo):**
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/setup-all-backups-cron.sh"
```

This will:
- Run all critical backups daily at 2:00 AM
- Keep last 30 backups for each service automatically
- Log to `/var/log/backup-all-critical.log`

**Verify automated backups are set up:**
```bash
grep backup /etc/crontab
```

## 📦 Backup Locations

All backups are stored in `/mnt/ssd/backups/`:
```
/mnt/ssd/backups/
├── vaultwarden/    # Password vault backups
├── nextcloud/      # Nextcloud database & config
├── travelsync/     # Travel data backups
└── kitchenowl/     # Shopping lists backups
```

## 🔄 Backup Retention

- **All services:** Keep last 30 backups automatically
- **Old backups:** Automatically deleted when limit exceeded
- **Backup format:** Timestamped (YYYYMMDD-HHMMSS)

## ⚠️ Important Notes

1. **Vaultwarden backups stop the service briefly** to ensure data consistency
2. **Test your backups!** Periodically verify you can restore from backups
3. **Nextcloud user files** are not included in the backup script - consider backing up `/mnt/ssd/apps/nextcloud/app/data/` separately if needed
4. **Before major changes** (container updates, config changes), run manual backups

## 📋 Backup Checklist

- [x] Vaultwarden backup script created
- [x] Nextcloud backup script created
- [x] TravelSync backup script created
- [x] KitchenOwl backup script created ✅
- [x] Combined backup script created
- [x] Automated backup setup script created
- [ ] **Run setup script to enable automated backups:**
  ```bash
  sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/setup-all-backups-cron.sh"
  ```

## 🧪 Test Backups

After setting up, test that backups work:
```bash
# Run manual backup
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-all-critical.sh"

# Check backups were created
ls -lh /mnt/ssd/backups/*/
```

## 📚 Related Documentation

- `KITCHENOWL_BACKUP_PREVENTION.md` - KitchenOwl specific backup guide
- `usefull files/QUICK_SSH_COMMANDS.md` - Quick reference for all commands

