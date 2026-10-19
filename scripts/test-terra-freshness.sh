#!/bin/bash
# Self-check for health.d/70-terra.sh. Run directly: bash scripts/test-terra-freshness.sh
#
# Deliberately NOT in health.d/ (the engine sources every *.sh there hourly).
# restic is a stub on PATH (the plugin calls it through `timeout`, so a shell
# function would not be seen); systemctl is a function. No network is used.
set -uo pipefail

PLUGIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/health.d/70-terra.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# The stub prints $TMP/out, or fails when $TMP/fail exists.
printf '#!/bin/sh\n[ -e "%s/fail" ] && { echo "Fatal: unable to open repository"; exit 1; }\ncat "%s/out"\n' "$TMP" "$TMP" > "$TMP/restic"
chmod +x "$TMP/restic"
PATH="$TMP:$PATH"

snap_at() { echo "[{\"time\":\"$(date -u -d "@$(( $(date +%s) - $1 * 3600 - 60 ))" +%Y-%m-%dT%H:%M:%S.123456789Z)\"}]" > "$TMP/out"; }

TIMER_ENABLED=0
systemctl() { [ "$TIMER_ENABLED" -eq 1 ]; }
log() { :; }
NOTIFIED=""
send_slack_notification() { NOTIFIED="$1 $2"; }

fail=0
check() {
    if [ "$2" = "$3" ]; then echo "  ok: $1"; else echo "  FAIL: $1 (expected '$3', got '$2')"; fail=1; fi
}
# shellcheck source=/dev/null
run() { NOTIFIED=""; source "$PLUGIN"; }

echo "terra freshness plugin:"
snap_at 100
run
check "silent before setup (timer not enabled)" "${NOTIFIED:-<none>}" "<none>"

TIMER_ENABLED=1
snap_at 2;  run; check "2h-old snapshot is quiet"   "${NOTIFIED:-<none>}" "<none>"
snap_at 48; run; check "48h-old snapshot is quiet"  "${NOTIFIED:-<none>}" "<none>"
snap_at 49; run; check "49h-old snapshot alarms"    "$(grep -c stale <<<"$NOTIFIED")" "1"
echo "[]" > "$TMP/out"; run
check "empty repo alarms"                            "$(grep -c 'no snapshot' <<<"$NOTIFIED")" "1"
touch "$TMP/fail"; run
check "unreachable repo alarms"                      "$(grep -c unreachable <<<"$NOTIFIED")" "1"

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; exit 1; fi
