#!/bin/bash
###############################################################################
# Restore drill: prove a backup can actually come back.
#
#   bash scripts/restore-drill.sh            # all services
#   bash scripts/restore-drill.sh linkwarden # one service
#
# backup-engine.sh verifies each archive as it writes it (.ok sidecar) and
# health.d/50-backup-freshness.sh asserts that sidecar hourly. Neither can tell
# you the archive contains the right THINGS. Linkwarden passed both for eight
# months while shipping no database at all (troubleshooting-log 2026-09-26).
# This script opens the backup and checks the data is really in there.
#
# Safe to run on production. Every check works on a copy in a temp directory,
# and any container it starts is throwaway, bound to 127.0.0.1 on an unused
# port, and removed on exit including Ctrl-C. Live services are never touched.
#
# Run after any upgrade to one of these services, and monthly otherwise.
#
# ponytail: checks are per-service because the backups genuinely differ (SQLite
# file, pg_dump, tarred directory). Shared scaffolding, one function each.
# Ceiling: does not decrypt a Vaultwarden cipher (needs the master password)
# and does not boot Nextcloud or Linkwarden as full apps, it only proves their
# databases load and contain the expected rows.
###############################################################################
set -uo pipefail

SERVICES="vaultwarden nextcloud travelsync kitchenowl linkwarden"
BACKUP_ROOT="/mnt/ssd/backups"
PG_IMAGE="postgres:16-alpine"

fails=0
ok()  { echo "    ok: $1"; }
bad() { echo "    FAIL: $1"; fails=$((fails + 1)); }
# if/else helpers rather than `test && ok || bad`, which silently reports a pass
# whenever ok() itself returns non-zero.
want_file() { if [ -f "$1" ]; then ok "$2"; else bad "$3"; fi; }
want_dir()  { if [ -d "$1" ]; then ok "$2"; else bad "$3"; fi; }
want_set()  { if [ -n "$1" ]; then ok "$2"; else bad "$3"; fi; }
want_gt()   { if [ "${1:-0}" -gt "$2" ]; then ok "$3"; else bad "$4"; fi; }
want_eq()   { if [ "$1" = "$2" ]; then ok "$3"; else bad "$4"; fi; }

WORK=$(mktemp -d "${HOME}/.restore-drill-XXXXXX")
CONTAINERS=""
cleanup() {
    for c in $CONTAINERS; do docker rm -f "$c" >/dev/null 2>&1; done
    rm -rf "$WORK"
}
trap cleanup EXIT INT TERM

newest() {   # newest <dir> <glob>
    # shellcheck disable=SC2012,SC2086  # engine-generated timestamps; glob must expand
    ls -t "$1"/$2 2>/dev/null | head -1
}

# Boot a throwaway Postgres and leave it running for queries. Returns non-zero
# only if the server never became usable.
pg_start() {   # pg_start <name>
    local name="$1" i
    docker rm -f "$name" >/dev/null 2>&1
    docker run -d --name "$name" -e POSTGRES_PASSWORD=drill \
        "$PG_IMAGE" >/dev/null 2>&1 || return 1
    CONTAINERS="$CONTAINERS $name"
    # Two-stage wait, and both stages are necessary.
    #
    # The official image runs initdb against a TEMPORARY server on the same unix
    # socket, then stops it and starts the real one. Both pg_isready and even a
    # real `select 1` answer yes against that temporary server, so either alone
    # returns "ready" too early and the dump load then dies mid-way with
    # "connection to server on socket ... failed". Observed exactly that.
    #
    # So: first wait for the image to announce init is finished, then wait for
    # the real server to answer a query.
    for i in $(seq 1 60); do
        docker logs "$name" 2>&1 | grep -q "init process complete" && break
        sleep 1
    done
    for i in $(seq 1 60); do
        docker exec "$name" psql -U postgres -tAc 'select 1' postgres >/dev/null 2>&1 && return 0
        sleep 1
    done
    return 1
}

# Load the roles dump. Errors are tolerated: a fresh Postgres already has the
# postgres role, so "role already exists" is expected and harmless.
pg_load_globals() {   # pg_load_globals <name> <globalsfile>
    local name="$1" globals="$2"
    [ -n "$globals" ] || return 0
    docker exec -i "$name" psql -U postgres -q -v ON_ERROR_STOP=0 postgres \
        < "$globals" >/dev/null 2>&1
    return 0
}

# Load a dump into an already-running throwaway Postgres. Echoes psql's stderr
# on failure so the reason is visible rather than guessed at.
pg_load() {   # pg_load <name> <dumpfile>
    local name="$1" dump="$2"
    docker exec -i "$name" psql -U postgres -q -v ON_ERROR_STOP=1 postgres \
        < "$dump" >/dev/null 2>"$WORK/pgerr.txt"
}

pg_count() {   # pg_count <container> <sql>
    docker exec "$1" psql -U postgres -tAc "$2" postgres 2>/dev/null | tr -d '[:space:]'
}

sqlite_check() {   # sqlite_check <file> <label>
    local res
    res=$(python3 -c "import sqlite3,sys;print(sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True).execute('PRAGMA integrity_check').fetchone()[0])" "$1" 2>/dev/null)
    if [ "$res" = "ok" ]; then ok "$2 passes integrity_check"; else bad "$2 integrity_check: ${res:-unreadable}"; fi
}

sqlite_tables() {   # sqlite_tables <file>
    python3 -c "import sqlite3,sys;print(sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True).execute(\"select count(*) from sqlite_master where type='table'\").fetchone()[0])" "$1" 2>/dev/null
}

###############################################################################

drill_vaultwarden() {
    local arch dir port=8077 code i restored live
    arch=$(newest "$BACKUP_ROOT/vaultwarden" "vaultwarden-*.tar.gz")
    [ -n "$arch" ] || { bad "no archive found"; return; }
    echo "    archive: $(basename "$arch")"
    dir="$WORK/vw"; mkdir -p "$dir"
    tar -xzf "$arch" -C "$dir" 2>/dev/null || { bad "does not extract"; return; }

    if [ ! -f "$dir/db.sqlite3" ]; then bad "db.sqlite3 MISSING"; return; fi
    ok "db.sqlite3 present"
    # Without rsa_key.pem every session and 2FA-remember device is invalidated.
    # The archive looks complete without it, so assert it explicitly.
    want_file "$dir/rsa_key.pem" "rsa_key.pem present" "rsa_key.pem MISSING"
    sqlite_check "$dir/db.sqlite3" "vault db"

    chmod -R u+rwX "$dir"
    docker run -d --name vw-drill -v "$dir:/data" -p "127.0.0.1:$port:80" \
        -e DOMAIN="http://localhost:$port" -e SIGNUPS_ALLOWED=false \
        vaultwarden/server:1.37.3 >/dev/null 2>&1 || { bad "container would not start"; return; }
    CONTAINERS="$CONTAINERS vw-drill"
    for i in $(seq 1 30); do
        code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$port/" 2>/dev/null)
        [ "$code" = "200" ] && break
        sleep 1
    done
    want_eq "$code" "200" "restored vault serves HTTP 200 (${i}s)" "restored vault did not serve (${code:-none})"

    restored=$(python3 -c "import sqlite3;print(sqlite3.connect('$dir/db.sqlite3').execute('select count(*) from ciphers').fetchone()[0])" 2>/dev/null)
    live=$(python3 -c "import sqlite3;print(sqlite3.connect('file:/home/docker-projects/vaultwarden/data/db.sqlite3?mode=ro',uri=True).execute('select count(*) from ciphers').fetchone()[0])" 2>/dev/null)
    echo "    passwords: restored=${restored:-?} live=${live:-?}"
    want_gt "$restored" 0 "vault has entries" "vault is EMPTY"
}

drill_nextcloud() {
    local arch dir sql conf globals
    arch=$(newest "$BACKUP_ROOT/nextcloud" "nextcloud-*.tar.gz")
    [ -n "$arch" ] || { bad "no archive found"; return; }
    echo "    archive: $(basename "$arch")"
    dir="$WORK/nc"; mkdir -p "$dir"
    tar -xzf "$arch" -C "$dir" 2>/dev/null || { bad "does not extract"; return; }

    sql=$(find "$dir" -name "*-db-*.sql" | head -1)
    conf=$(find "$dir" -name "*-config-*.tar.gz" | head -1)
    globals=$(find "$dir" -name "*-globals-*.sql" | head -1)
    if [ -z "$sql" ]; then bad "db dump MISSING"; return; fi
    ok "db dump present ($(wc -l < "$sql") lines)"
    want_set "$conf" "config archive present" "config archive MISSING"
    want_set "$globals" "roles dump present" "roles dump MISSING (bare-metal restore would fail)"

    # config.php carries passwordsalt/secret/instanceid. Without them a restored
    # Nextcloud cannot decrypt anything, so the file being present is not enough.
    if [ -n "$conf" ]; then
        tar -xzf "$conf" -C "$dir" 2>/dev/null
        local missing=""
        for key in instanceid passwordsalt secret; do
            grep -q "$key" "$dir/config.php" 2>/dev/null || missing="$missing $key"
        done
        if [ -z "$missing" ]; then
            ok "config.php has instanceid, passwordsalt, secret"
        else
            bad "config.php missing:$missing"
        fi
    fi

    if ! pg_start nc-drill; then bad "throwaway postgres never became ready"; return; fi
    # Roles first. pg_dump emits OWNER TO / GRANT for roles it never creates, so
    # without the globals a bare-metal restore dies on the first missing role.
    pg_load_globals nc-drill "$globals"
    if ! pg_load nc-drill "$sql"; then
        bad "dump failed to load: $(head -1 "$WORK/pgerr.txt" 2>/dev/null)"
        return
    fi
    ok "dump loads into a clean postgres"
    local tables users
    tables=$(pg_count nc-drill "select count(*) from information_schema.tables where table_schema='public';")
    users=$(pg_count nc-drill "select count(*) from oc_users;")
    echo "    tables=${tables:-?} users=${users:-?}"
    want_gt "$tables" 20 "schema restored ($tables tables)" "too few tables restored (${tables:-0})"
    want_gt "$users" 0 "user accounts restored" "no user accounts in restore"
}

drill_travelsync() {
    local arch dir
    arch=$(newest "$BACKUP_ROOT/travelsync" "travelsync-*.tar.gz")
    [ -n "$arch" ] || { bad "no archive found"; return; }
    echo "    archive: $(basename "$arch")"
    dir="$WORK/ts"; mkdir -p "$dir"
    tar -xzf "$arch" -C "$dir" 2>/dev/null || { bad "does not extract"; return; }

    if [ ! -f "$dir/documents_calendar.db" ]; then bad "database MISSING"; return; fi
    ok "database present"
    sqlite_check "$dir/documents_calendar.db" "travelsync db"
    # Google OAuth material: without these the restored service cannot talk to
    # Calendar and needs a manual reauthorisation.
    want_file "$dir/credentials.json" "credentials.json present" "credentials.json MISSING"
    want_file "$dir/token.pickle" "token.pickle present" "token.pickle MISSING"
}

drill_kitchenowl() {
    local arch tables alembic
    arch=$(newest "$BACKUP_ROOT/kitchenowl" "kitchenowl-*.db")
    [ -n "$arch" ] || { bad "no archive found"; return; }
    echo "    archive: $(basename "$arch")"
    sqlite_check "$arch" "kitchenowl db"
    tables=$(sqlite_tables "$arch")
    echo "    tables=${tables:-?}"
    want_gt "$tables" 10 "schema present ($tables tables)" "too few tables (${tables:-0})"
    # alembic_version proves it is a real migrated KitchenOwl DB, not a stub.
    alembic=$(python3 -c "
import sqlite3,sys
c=sqlite3.connect('file:'+sys.argv[1]+'?mode=ro',uri=True)
v=c.execute('select version_num from alembic_version').fetchone()
print(v[0] if v else '')" "$arch" 2>/dev/null)
    want_set "$alembic" "alembic schema version present" "no alembic_version row"
}

drill_linkwarden() {
    local arch dir sql links globals
    arch=$(newest "$BACKUP_ROOT/linkwarden" "linkwarden-*.tar.gz")
    [ -n "$arch" ] || { bad "no archive found"; return; }
    echo "    archive: $(basename "$arch")"
    dir="$WORK/lw"; mkdir -p "$dir"
    tar -xzf "$arch" -C "$dir" 2>/dev/null || { bad "does not extract"; return; }

    sql=$(find "$dir" -name "*-db-*.sql" | head -1)
    globals=$(find "$dir" -name "*-globals-*.sql" | head -1)
    # The regression guard: archives before 2026-09-26 had no dump at all.
    if [ -z "$sql" ]; then bad "NO DATABASE IN BACKUP (bookmarks would be lost)"; return; fi
    ok "db dump present ($(wc -l < "$sql") lines)"
    want_dir "$dir/data" "data/ present (page snapshots)" "data/ MISSING"
    want_set "$globals" "roles dump present" "roles dump MISSING (bare-metal restore would fail)"

    if ! pg_start lw-drill; then bad "throwaway postgres never became ready"; return; fi
    # Roles first. pg_dump emits OWNER TO / GRANT for roles it never creates, so
    # without the globals a bare-metal restore dies on the first missing role.
    pg_load_globals lw-drill "$globals"
    if ! pg_load lw-drill "$sql"; then
        bad "dump failed to load: $(head -1 "$WORK/pgerr.txt" 2>/dev/null)"
        return
    fi
    ok "dump loads into a clean postgres"
    links=$(pg_count lw-drill 'select count(*) from "Link";')
    local users
    users=$(pg_count lw-drill 'select count(*) from "User";')
    echo "    bookmarks=${links:-?} users=${users:-?}"
    want_gt "$links" 0 "bookmarks restored" "no bookmarks in restore"
    want_gt "$users" 0 "user accounts restored" "no users in restore"
}

###############################################################################

targets="${1:-all}"
[ "$targets" = "all" ] && targets="$SERVICES"

for svc in $targets; do
    case " $SERVICES " in
        *" $svc "*) ;;
        *) echo "unknown service: $svc (known: $SERVICES)"; exit 1 ;;
    esac
done

echo "Restore drill"
echo
for svc in $targets; do
    before=$fails
    echo "  $svc:"
    "drill_$svc"
    if [ "$fails" -eq "$before" ]; then echo "    -> PASS"; else echo "    -> FAIL"; fi
    echo
done

if [ "$fails" -eq 0 ]; then
    echo "ALL RESTORE DRILLS PASSED"
else
    echo "RESTORE DRILLS FAILED: $fails check(s)"
    exit 1
fi
