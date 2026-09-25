#!/bin/bash
# Self-check for health.d/50-backup-freshness.sh. Run directly: bash scripts/test-backup-freshness.sh
#
# Deliberately NOT in health.d/ — health-check-engine.sh sources every *.sh in
# that directory, so a test living there would run in production every hour.
set -uo pipefail

PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/health.d/50-backup-freshness.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/backup.d" "$TMP/fresh_dir" "$TMP/stale_dir" "$TMP/empty_dir"

make_conf() {
    cat > "$TMP/backup.d/$1.conf" <<EOF
SERVICE_NAME="$2"
DST_DIR="$TMP/$3"
FILENAME_PREFIX="$1"
EXTENSION="tar.gz"
EOF
}

make_conf fresh FreshSvc fresh_dir
make_conf stale StaleSvc stale_dir
make_conf empty EmptySvc empty_dir

touch -d "1 hour ago"   "$TMP/fresh_dir/fresh-20260925-000000.tar.gz"
touch -d "72 hours ago" "$TMP/stale_dir/stale-20260922-000000.tar.gz"
# empty_dir intentionally left with no archive at all

# Stub the engine-provided helpers the plugin expects.
log() { :; }
NOTIFIED=""
send_slack_notification() { NOTIFIED="$2"; }
# Read by the plugin once sourced, not by this script.
# shellcheck disable=SC2034
SCRIPT_DIR="$TMP"

# shellcheck source=/dev/null
source "$PLUGIN"

fail=0
check() {
    if [ "$2" = "$3" ]; then
        echo "  ok: $1"
    else
        echo "  FAIL: $1 (expected '$3', got '$2')"
        fail=1
    fi
}

echo "backup freshness plugin:"
check "stale backup is reported"      "$(grep -c StaleSvc <<<"$NOTIFIED")" "1"
check "missing backup is reported"    "$(grep -c EmptySvc <<<"$NOTIFIED")" "1"
check "fresh backup is NOT reported"  "$(grep -c FreshSvc <<<"$NOTIFIED")" "0"

# All-fresh case must stay silent, otherwise the alarm cries wolf hourly and
# gets muted, which is how the original outage stayed invisible.
rm -f "$TMP/backup.d/stale.conf" "$TMP/backup.d/empty.conf"
NOTIFIED=""
# shellcheck source=/dev/null
source "$PLUGIN"
check "all-fresh sends no notification" "${NOTIFIED:-<none>}" "<none>"

# A backup exactly at its limit must not alarm; one hour past it must.
rm -f "$TMP/backup.d/fresh.conf"
make_conf edge EdgeSvc stale_dir
echo 'MAX_AGE_HOURS=72' >> "$TMP/backup.d/edge.conf"
mv "$TMP/stale_dir/stale-20260922-000000.tar.gz" "$TMP/stale_dir/edge-20260922-000000.tar.gz"
NOTIFIED=""
# shellcheck source=/dev/null
source "$PLUGIN"
check "at the age limit stays quiet"   "${NOTIFIED:-<none>}" "<none>"

touch -d "73 hours ago" "$TMP/stale_dir/edge-20260922-000000.tar.gz"
NOTIFIED=""
# shellcheck source=/dev/null
source "$PLUGIN"
check "one hour past the limit alarms" "$(grep -c EdgeSvc <<<"$NOTIFIED")" "1"

if [ "$fail" -eq 0 ]; then
    echo "PASS"
else
    echo "FAILED"
    exit 1
fi
