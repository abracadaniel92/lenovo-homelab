#!/bin/bash
# Sync backups to Backblaze B2
# Runs daily after local backups complete (3 AM)

LOG_FILE="/var/log/rclone-sync.log"
BACKUP_DIR="/mnt/ssd/backups"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting B2 sync..." >> "$LOG_FILE"

# Exclude problematic directory if it exists
rclone sync "$BACKUP_DIR/" b2-backup:Goce-Lenovo/ \
  --exclude "nextcloud-data-extra-*/data/**" \
  --delete-after \
  --log-file="$LOG_FILE" \
  --log-level INFO \
  --progress 2>&1 | tee -a "$LOG_FILE"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync completed successfully" >> "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync completed with warnings" >> "$LOG_FILE"
fi
