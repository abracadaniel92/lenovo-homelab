#!/bin/bash
# Sync backups to Backblaze B2
# Runs daily after local backups complete (3 AM)

LOG_FILE="/var/log/rclone-sync.log"
BACKUP_DIR="/mnt/ssd/backups"
RCLONE_USER="goce"

# Ensure log file exists and is writable
touch "$LOG_FILE" 2>/dev/null || sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE" 2>/dev/null || true

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting B2 sync..." | tee -a "$LOG_FILE"

# --backup-dir turns this from a mirror into an archive. Plain `rclone sync`
# propagates local deletions offsite, so anything that destroyed or truncated a
# local archive (retention pruning after months of missed runs, a bad backup
# overwriting a good one, ransomware) reached B2 within 24 hours and took the
# only offsite copy with it. Superseded and deleted files now land in a dated
# folder instead of being erased.
ARCHIVE_DIR="b2-backup:Goce-Lenovo-superseded/$(date +%Y-%m-%d)"

# Run rclone as the goce user (where rclone config is stored)
sudo -u "$RCLONE_USER" rclone sync "$BACKUP_DIR/" b2-backup:Goce-Lenovo/ \
  --exclude "nextcloud-data-extra-*/data/**" \
  --delete-after \
  --backup-dir "$ARCHIVE_DIR" \
  --log-file="$LOG_FILE" \
  --log-level INFO \
  --progress 2>&1 | tee -a "$LOG_FILE"

SYNC_EXIT_CODE=${PIPESTATUS[0]}

if [ "$SYNC_EXIT_CODE" -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync completed successfully" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync completed with warnings (exit code: $SYNC_EXIT_CODE)" | tee -a "$LOG_FILE"
fi

exit "$SYNC_EXIT_CODE"
