#!/bin/bash
# Self-check for health.d/60-offsite-freshness.sh. Run directly: bash scripts/test-offsite-freshness.sh
#
# Deliberately NOT in health.d/ (the engine sources every *.sh there hourly).
# rclone and systemctl are stubbed as shell functions, so no network is used.
set -uo pipefail

PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/health.d/60-offsite-freshness.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/backup.d"

make_conf() {
    printf 'SERVICE_NAME="%s"\nFILENAME_PREFIX="%s"\nEXTENSION="tar.gz"\n' "$2" "$1" > "$TMP/backup.d/$1.conf"
}
make_conf fresh FreshSvc
make_conf stale StaleSvc
make_conf gone  GoneSvc

now=$(date +%s)
LISTING="$((now - 3600))|fresh/fresh-20260926-020000.tar.gz
$((now - 100*3600))|stale/stale-20260922-020000.tar.gz
$((now - 60))|stale/stale-20260926-020000.tar.gz.ok
$((now - 60))|gone/unrelated-20260926.tar.gz"

RCLONE_FAILS=0
TIMER_ENABLED=0
rclone() { [ "$RCLONE_FAILS" -eq 1 ] && { echo "Failed to lsf: couldn't find remote"; return 1; }; echo "$LISTING"; }
systemctl() { [ "$TIMER_ENABLED" -eq 1 ]; }
log() { :; }
NOTIFIED=""
send_slack_notification() { NOTIFIED="$1 $2"; }
# shellcheck disable=SC2034  # read by the plugin
SCRIPT_DIR="$TMP"

fail=0
check() {
    if [ "$2" = "$3" ]; then echo "  ok: $1"; else echo "  FAIL: $1 (expected '$3', got '$2')"; fail=1; fi
}
# shellcheck source=/dev/null
run() { NOTIFIED=""; source "$PLUGIN"; }

echo "offsite freshness plugin:"
run
check "silent before setup (timer not enabled)" "${NOTIFIED:-<none>}" "<none>"

TIMER_ENABLED=1
run
check "stale copy reported (newer .ok ignored)" "$(grep -c StaleSvc <<<"$NOTIFIED")" "1"
check "missing offsite copy is reported"         "$(grep -c GoneSvc <<<"$NOTIFIED")" "1"
check "fresh offsite copy is NOT reported"       "$(grep -c FreshSvc <<<"$NOTIFIED")" "0"

# At 72h (48 + 24 grace) stays quiet, one hour past alarms.
rm "$TMP/backup.d/gone.conf"
LISTING="$((now - 3600))|fresh/fresh-20260926-020000.tar.gz
$((now - 72*3600))|stale/stale-20260923-020000.tar.gz"
run
check "at max age + grace stays quiet" "${NOTIFIED:-<none>}" "<none>"
LISTING="$((now - 3600))|fresh/fresh-20260926-020000.tar.gz
$((now - 73*3600 - 60))|stale/stale-20260923-020000.tar.gz"
run
check "one hour past it alarms"        "$(grep -c StaleSvc <<<"$NOTIFIED")" "1"

# A listing failure (network, missing crypt remote, bad key) must be loud.
RCLONE_FAILS=1
run
check "unlistable remote alarms" "$(grep -c unreadable <<<"$NOTIFIED")" "1"

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; exit 1; fi
