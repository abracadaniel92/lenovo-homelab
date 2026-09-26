#!/bin/bash
###############################################################################
# Vaultwarden restore drill
#
#   bash scripts/restore-drill-vaultwarden.sh
#
# Proves the newest Vaultwarden backup can come back as a WORKING vault, not
# merely that the archive is readable. backup-engine.sh already verifies the
# archive when it writes it (.ok sidecar) and health.d/50-backup-freshness.sh
# asserts that sidecar hourly, but "readable" is not "restorable": neither
# catches a backup that is missing rsa_key.pem, or a schema the current image
# refuses to open.
#
# Safe to run on production. It uses a throwaway container name, a temp data
# directory, and port 8077. It never touches the live container, the live data
# directory, or port 8082. Cleans up on any exit, including Ctrl-C.
#
# Run it after any Vaultwarden upgrade, and every month or so otherwise.
#
# ponytail: Vaultwarden only, because it is the one service where a silent
# backup failure is unrecoverable (lose the vault, lose every credential).
# Ceiling: does not test the other 4 services, and does not test decrypting an
# actual cipher, which would need the master password. Upgrade path is to drive
# it from scripts/backup.d/*.conf once a second service is worth the effort.
###############################################################################
set -uo pipefail

BACKUP_DIR="/mnt/ssd/backups/vaultwarden"
LIVE_DB="/home/docker-projects/vaultwarden/data/db.sqlite3"
IMAGE="vaultwarden/server:1.37.3"
NAME="vaultwarden-restoredrill"
PORT=8077

fails=0
ok()   { echo "  ok: $1"; }
bad()  { echo "  FAIL: $1"; fails=$((fails + 1)); }

if [ "$(docker ps -aq -f name="^/${NAME}$")" ]; then
    echo "A previous drill container is still present. Removing it."
    docker rm -f "$NAME" >/dev/null 2>&1
fi

WORK=$(mktemp -d "${HOME}/.restore-drill-XXXXXX")
cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1
    rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

# shellcheck disable=SC2012  # names are engine-generated timestamps: no newlines, no globs
ARCHIVE=$(ls -t "$BACKUP_DIR"/vaultwarden-*.tar.gz 2>/dev/null | head -1)
if [ -z "$ARCHIVE" ]; then
    echo "FAIL: no backup archive found in $BACKUP_DIR"
    exit 1
fi
echo "Restore drill: $(basename "$ARCHIVE")"
echo

echo "1. Extract"
mkdir -p "$WORK/data"
if tar -xzf "$ARCHIVE" -C "$WORK/data" 2>/dev/null; then
    ok "archive extracts"
else
    bad "archive does not extract"
    exit 1
fi
if [ -f "$WORK/data/db.sqlite3" ]; then ok "db.sqlite3 present"; else bad "db.sqlite3 MISSING"; fi
# Without rsa_key.pem every session token and 2FA-remember device is invalidated
# on restore. The archive looks fine without it, which is why this is asserted.
if [ -f "$WORK/data/rsa_key.pem" ]; then ok "rsa_key.pem present"; else bad "rsa_key.pem MISSING"; fi
[ "$fails" -eq 0 ] || exit 1

echo
echo "2. Contents"
python3 - "$WORK/data/db.sqlite3" <<'PY'
import sqlite3, sys
c = sqlite3.connect(sys.argv[1])
for label, q in [("ciphers", "select count(*) from ciphers"),
                 ("users",   "select count(*) from users"),
                 ("folders", "select count(*) from folders"),
                 ("newest",  "select max(updated_at) from ciphers")]:
    print(f"  {label:8} {c.execute(q).fetchone()[0]}")
PY

echo
echo "3. Boot a throwaway instance on 127.0.0.1:$PORT"
chmod -R u+rwX "$WORK/data"
if ! docker run -d --name "$NAME" \
        -v "$WORK/data:/data" \
        -p "127.0.0.1:$PORT:80" \
        -e DOMAIN="http://localhost:$PORT" \
        -e SIGNUPS_ALLOWED=false \
        "$IMAGE" >/dev/null 2>&1; then
    bad "container would not start"
    exit 1
fi

code=""
for i in $(seq 1 30); do
    code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/" 2>/dev/null)
    [ "$code" = "200" ] && break
    sleep 1
done
if [ "$code" = "200" ]; then
    ok "restored vault serves HTTP 200 (after ${i}s)"
else
    bad "restored vault did not serve (last code: ${code:-none})"
    docker logs "$NAME" 2>&1 | tail -15
    exit 1
fi

errs=$(docker logs "$NAME" 2>&1 | grep -ci 'error\|panic')
if [ "$errs" -eq 0 ]; then ok "no errors in startup log"; else bad "$errs error lines in startup log"; fi

echo
echo "4. Restored vs live"
restored=$(python3 -c "import sqlite3;print(sqlite3.connect('$WORK/data/db.sqlite3').execute('select count(*) from ciphers').fetchone()[0])" 2>/dev/null)
live=$(python3 -c "import sqlite3;print(sqlite3.connect('file:$LIVE_DB?mode=ro',uri=True).execute('select count(*) from ciphers').fetchone()[0])" 2>/dev/null)
echo "  restored: ${restored:-?} ciphers"
echo "  live:     ${live:-?} ciphers"
if [ -n "$restored" ] && [ "$restored" = "$live" ]; then
    ok "counts match"
elif [ -n "$restored" ] && [ -n "$live" ] && [ "$restored" -lt "$live" ]; then
    # Not a failure: entries added since the backup ran are legitimately absent.
    ok "restored is behind live by $((live - restored)), expected if you added entries since the last backup"
else
    bad "could not compare restored against live"
fi

echo
if [ "$fails" -eq 0 ]; then
    echo "RESTORE DRILL PASSED"
else
    echo "RESTORE DRILL FAILED: $fails check(s)"
    exit 1
fi
