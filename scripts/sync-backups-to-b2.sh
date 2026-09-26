#!/bin/bash
# Sync backups to Backblaze B2 (client-side encrypted)
# Runs daily after local backups complete, from sync-backups-to-b2.timer (03:00)
# as User=goce, so the rclone config in goce's home is used directly. Exits
# non-zero on failure, which fires notify-failure@ via OnFailure=.
#
# b2-crypt is an rclone crypt remote over b2-backup:Goce-Lenovo-crypt, created by
# setup-b2-encrypted-sync.sh. File contents AND names are encrypted before they
# leave the box: the TravelSync archive holds live Google OAuth credentials
# (troubleshooting-log 2026-09-26). The crypt passwords live only in goce's
# rclone.conf and wherever you copied them; lose both and every offsite copy is
# unrecoverable.

LOG_FILE="/var/log/rclone-sync.log"
BACKUP_DIR="/mnt/ssd/backups"
REMOTE="b2-crypt:current"
SUPERSEDED="b2-crypt:superseded"
SUPERSEDED_KEEP_DAYS=90

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting B2 sync..." | tee -a "$LOG_FILE"

# --backup-dir turns this from a mirror into an archive. Plain `rclone sync`
# propagates local deletions offsite, so anything that destroyed or truncated a
# local archive (retention pruning after months of missed runs, a bad backup
# overwriting a good one, ransomware) reached B2 within 24 hours and took the
# only offsite copy with it. Superseded and deleted files now land in a dated
# folder instead of being erased. It must sit on the same crypt remote as the
# destination (non-overlapping path) so rclone can move files server side.
rclone sync "$BACKUP_DIR/" "$REMOTE/" \
  --exclude "nextcloud-data-extra-*/data/**" \
  --delete-after \
  --backup-dir "$SUPERSEDED/$(date +%Y-%m-%d)" \
  --log-file="$LOG_FILE" \
  --log-level INFO
SYNC_EXIT_CODE=$?

# Prune dated superseded folders by their NAME (the day they were superseded),
# not by file mtime: an archive created 100 days ago and deleted locally today
# must still get its full grace period. YYYY-MM-DD sorts as a string.
cutoff=$(date -d "-${SUPERSEDED_KEEP_DAYS} days" +%Y-%m-%d)
rclone lsf --dirs-only "$SUPERSEDED/" 2>/dev/null | tr -d / | while read -r day; do
    [[ "$day" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$day" < "$cutoff" ]] || continue
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pruning superseded/$day (older than ${SUPERSEDED_KEEP_DAYS}d)" | tee -a "$LOG_FILE"
    rclone purge "$SUPERSEDED/$day" --log-file="$LOG_FILE" --log-level INFO
done

if [ "$SYNC_EXIT_CODE" -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync completed successfully" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync FAILED (exit code: $SYNC_EXIT_CODE)" | tee -a "$LOG_FILE"
fi

exit "$SYNC_EXIT_CODE"
