#!/bin/bash
###############################################################################
# Unified Backup Engine
# Dynamically executes backups based on configuration files in backup.d/
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RETENTION_HELPER="$SCRIPT_DIR/backup-retention-helper.sh"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

usage() {
    echo "Usage: $0 <service_config_name>"
    echo "Example: $0 vaultwarden"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

CONF_FILE="$SCRIPT_DIR/backup.d/$1.conf"

if [ ! -f "$CONF_FILE" ]; then
    log "❌ ERROR: Configuration file not found: $CONF_FILE"
    exit 1
fi

# Load configuration
source "$CONF_FILE"

# Prepare paths
mkdir -p "$DST_DIR"
BACKUP_FILE="${DST_DIR}/${FILENAME_PREFIX}-${TIMESTAMP}.${EXTENSION}"

log "🔄 Starting backup for: $SERVICE_NAME"

case "$TYPE" in
    "DOCKER_TAR")
        log "   Stopping container: $CONTAINER..."
        cd "$DOCKER_DIR" && docker compose stop "$CONTAINER"
        
        log "   Creating archive..."
        tar_args=("-czf" "$BACKUP_FILE")
        for exc in $EXCLUDES; do
            tar_args+=("--exclude=$exc")
        done
        tar "${tar_args[@]}" -C "$SRC_PATH" . 2>/dev/null || {
            log "❌ Backup failed!"
            docker compose start "$CONTAINER"
            exit 1
        }
        
        log "   Starting container: $CONTAINER..."
        docker compose start "$CONTAINER"
        ;;

    "PG_DUMP_AND_TAR")
        log "   Dumping database: $DB_NAME..."
        DB_TEMP="/tmp/${FILENAME_PREFIX}-db-${TIMESTAMP}.sql"
        docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" > "$DB_TEMP" || {
            log "❌ Database dump failed!"
            exit 1
        }
        
        log "   Backing up configuration..."
        CONF_TEMP="/tmp/${FILENAME_PREFIX}-config-${TIMESTAMP}.tar.gz"
        tar -czf "$CONF_TEMP" -C "$CONFIG_SRC" "$CONFIG_FILE" 2>/dev/null || log "⚠️  Config backup skipped"
        
        log "   Creating combined archive..."
        tar -czf "$BACKUP_FILE" -C /tmp "$(basename "$DB_TEMP")" "$(basename "$CONF_TEMP")" 2>/dev/null || {
            log "❌ Backup archive creation failed!"
            rm -f "$DB_TEMP" "$CONF_TEMP"
            exit 1
        }
        rm -f "$DB_TEMP" "$CONF_TEMP"
        ;;

    "TAR")
        log "   Creating archive of $SRC_PATH..."
        tar -czf "$BACKUP_FILE" -C "$SRC_PATH" . 2>/dev/null || {
            log "❌ Backup failed!"
            exit 1
        }
        ;;

    "TAR_DIR")
        log "   Creating archive of subdirectories in $SRC_DIR..."
        cd "$SRC_DIR"
        tar -czf "$BACKUP_FILE" $SUBDIRS 2>/dev/null || {
             # Fallback to creating with what exists if some dirs are missing
             tar -czf "$BACKUP_FILE" $SUBDIRS 2>/dev/null || true
        }
        ;;

    "FILE")
        log "   Copying file: $SRC_PATH..."
        if [ ! -f "$SRC_PATH" ]; then
            log "❌ ERROR: Source file not found: $SRC_PATH"
            exit 1
        fi
        cp "$SRC_PATH" "$BACKUP_FILE"
        ;;

    *)
        log "❌ ERROR: Unknown backup type: $TYPE"
        exit 1
        ;;
esac

# Set permissions
chmod 644 "$BACKUP_FILE"
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log "✅ Backup created: $(basename "$BACKUP_FILE") ($FILE_SIZE)"

# Smart retention cleanup
if [ -f "$RETENTION_HELPER" ]; then
    log "   Running smart retention cleanup..."
    source "$RETENTION_HELPER"
    smart_retention_cleanup "$DST_DIR" "${FILENAME_PREFIX}-*.${EXTENSION}" "$SERVICE_NAME"
else
    log "⚠️  WARNING: Retention helper not found at $RETENTION_HELPER"
fi

log "✅ $SERVICE_NAME backup complete!"
