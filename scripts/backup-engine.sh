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

is_sqlite() {
    [ -f "$1" ] && [ "$(head -c 15 "$1" 2>/dev/null)" = "SQLite format 3" ]
}

# Consistent copy of a live SQLite database via the online backup API, which
# reads THROUGH the -wal file. Replaces the old stop-container-then-tar dance,
# which raced SQLite's shutdown checkpoint and silently shipped archives missing
# every write still sitting in the WAL. See troubleshooting-log 2026-09-25:
# a Vaultwarden backup came out 7 weeks stale that way. Verifies the result
# before returning, so a corrupt snapshot fails the backup instead of quietly
# replacing a good one.
sqlite_snapshot() {
    python3 - "$1" "$2" <<'PY'
import sqlite3, sys
src = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
dst = sqlite3.connect(sys.argv[2])
with dst:
    src.backup(dst)
ok = dst.execute("PRAGMA integrity_check").fetchone()[0]
dst.close(); src.close()
if ok != "ok":
    sys.exit(f"integrity_check on snapshot returned: {ok}")
PY
}

if [ -z "$1" ]; then
    usage
fi

CONF_FILE="$SCRIPT_DIR/backup.d/$1.conf"

if [ ! -f "$CONF_FILE" ]; then
    log "❌ ERROR: Configuration file not found: $CONF_FILE"
    exit 1
fi

# Load configuration. Path is built from $1 at runtime, so shellcheck cannot
# follow it; every variable used below comes from here.
# shellcheck source=/dev/null
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
        # Nextcloud's config.php is mode 640 www-data:www-data while backups run as
        # goce, so the host-side tar below failed every night, was swallowed by
        # 2>/dev/null, and shipped a 45-byte empty archive with exit 0. Read it
        # through the container instead when CONFIG_CONTAINER is set: the container
        # owns the file, and goce is in the docker group.
        if [ -n "${CONFIG_CONTAINER:-}" ]; then
            # shellcheck disable=SC2153  # CONFIG_FILE comes from the sourced conf, not a typo for CONF_FILE
            docker exec "$CONFIG_CONTAINER" tar -czf - -C "$CONFIG_CONTAINER_DIR" "$CONFIG_FILE" > "$CONF_TEMP"
        else
            tar -czf "$CONF_TEMP" -C "$CONFIG_SRC" "$CONFIG_FILE"
        fi
        # config.php carries passwordsalt and secret; without them a restored
        # instance cannot decrypt anything. An empty archive here is a failed
        # backup, not a warning.
        tar -tzf "$CONF_TEMP" 2>/dev/null | grep -qF "$CONFIG_FILE" || {
            log "❌ Config backup is empty: $CONFIG_FILE not readable"
            rm -f "$DB_TEMP" "$CONF_TEMP"
            exit 1
        }

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
        # SUBDIRS is a space-separated list in the conf; the splitting is wanted.
        # shellcheck disable=SC2086
        tar -czf "$BACKUP_FILE" $SUBDIRS 2>/dev/null || {
             # Fallback to creating with what exists if some dirs are missing
             # shellcheck disable=SC2086
             tar -czf "$BACKUP_FILE" $SUBDIRS 2>/dev/null || true
        }
        ;;

    "FILE")
        if [ ! -f "$SRC_PATH" ]; then
            log "❌ ERROR: Source file not found: $SRC_PATH"
            exit 1
        fi
        if is_sqlite "$SRC_PATH"; then
            # A plain cp of a live SQLite file can capture a torn page mid-write
            # and drops anything still in the -wal. Same output filename, so
            # restore procedures are unaffected.
            log "   SQLite detected, taking online snapshot: $SRC_PATH..."
            sqlite_snapshot "$SRC_PATH" "$BACKUP_FILE"
        else
            log "   Copying file: $SRC_PATH..."
            cp "$SRC_PATH" "$BACKUP_FILE"
        fi
        ;;

    "SQLITE_TAR")
        # SQLite database + the rest of its data directory, no downtime.
        if [ ! -f "$SQLITE_DB" ]; then
            log "❌ ERROR: SQLite database not found: $SQLITE_DB"
            exit 1
        fi
        DB_NAME=$(basename "$SQLITE_DB")
        SNAP_DIR=$(mktemp -d)
        trap 'rm -rf "$SNAP_DIR"' EXIT

        log "   Snapshotting $DB_NAME..."
        sqlite_snapshot "$SQLITE_DB" "$SNAP_DIR/$DB_NAME"

        log "   Creating archive..."
        # Archive the snapshot, then the rest of the data dir with the live
        # database and its sidecars excluded (the snapshot supersedes them).
        tar_args=(
            "-czf" "$BACKUP_FILE"
            "-C" "$SNAP_DIR" "$DB_NAME"
            "-C" "$SRC_PATH"
            "--exclude=./$DB_NAME"
            "--exclude=./${DB_NAME}-wal"
            "--exclude=./${DB_NAME}-shm"
        )
        for exc in $EXCLUDES; do
            tar_args+=("--exclude=$exc")
        done
        tar "${tar_args[@]}" . || {
            log "❌ Backup failed!"
            exit 1
        }
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

# Verify the artifact we just wrote, then drop a .ok sidecar beside it.
#
# Why here and not in the hourly health check: this is the moment a bad backup
# is worth catching, and it costs one pass over a file we just built instead of
# re-reading every archive 24 times a day. scripts/health.d/50-backup-freshness.sh
# asserts the sidecar exists, which upgrades it from "a file appeared recently"
# to "a file appeared recently and was readable when written". That module's own
# comment named this as the upgrade path.
#
# Runs BEFORE retention cleanup on purpose: pruning must never run on the back
# of a backup that failed verification, or a corrupt newest archive takes the
# good older ones with it. That is how the 2026-09-25 Vaultwarden archives were
# lost.
verify_artifact() {
    case "$BACKUP_FILE" in
        *.tar.gz|*.tgz)
            # Decompresses and walks the member list, so this catches both a
            # truncated gzip stream and a corrupt tar structure.
            tar -tzf "$BACKUP_FILE" >/dev/null 2>&1 || return 1
            ;;
        *)
            if is_sqlite "$BACKUP_FILE"; then
                [ "$(python3 -c 'import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute("PRAGMA integrity_check").fetchone()[0])' \
                    "$BACKUP_FILE" 2>/dev/null)" = "ok" ] || return 1
            else
                [ -s "$BACKUP_FILE" ] || return 1
            fi
            ;;
    esac
}

log "   Verifying archive..."
if verify_artifact; then
    date -u +%Y-%m-%dT%H:%M:%SZ > "$BACKUP_FILE.ok"
    chmod 644 "$BACKUP_FILE.ok"
    log "   ✅ Verified"
else
    log "❌ Backup FAILED verification: $(basename "$BACKUP_FILE")"
    log "   Kept for inspection, no .ok sidecar written, retention NOT run."
    exit 1
fi

# Smart retention cleanup
if [ -f "$RETENTION_HELPER" ]; then
    log "   Running smart retention cleanup..."
    # shellcheck source=/dev/null
    source "$RETENTION_HELPER"
    smart_retention_cleanup "$DST_DIR" "${FILENAME_PREFIX}-*.${EXTENSION}" "$SERVICE_NAME"
else
    log "⚠️  WARNING: Retention helper not found at $RETENTION_HELPER"
fi

# Retention globs on "<prefix>-*.<ext>", which never matches a .ok sidecar, so
# pruned archives would leave theirs behind to accumulate forever.
for ok in "$DST_DIR"/*.ok; do
    [ -e "$ok" ] || continue          # glob did not match anything
    [ -e "${ok%.ok}" ] || rm -f "$ok"
done

log "✅ $SERVICE_NAME backup complete!"
