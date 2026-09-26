#!/bin/bash
###############################################################################
# Self-check for the health-check engine's global guards and health.d modules.
#
#   bash scripts/test-health-modules.sh
#
# Companion to scripts/test-backup-freshness.sh. Both exist because the
# 2026-01-28 outage was caused by checks that reported healthy while doing
# nothing, so the checks themselves now have to fail when they stop working.
#
# ponytail: stubs log()/send_slack_notification() for the module checks, and
# stands up a throwaway python http.server for the probe checks so they run
# against real HTTP status codes. Ceiling: docker and systemd are still not
# exercised, so container restarts and unit state go unproven here.
###############################################################################
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE="$SCRIPT_DIR/health-check-engine.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

fails=0
pass() { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; fails=$((fails + 1)); }
assert_set()   { if [ -n "$1" ]; then pass "$2"; else fail "$2"; fi; }
assert_empty() { if [ -z "$1" ]; then pass "$2"; else fail "$2"; fi; }

echo "cloudflared module (20-cloudflared.sh):"

# Regression guard: the alert title/body were assigned with `local` at module
# top level, where bash refuses the assignment. The most critical alert in the
# homelab (external access down, @all) went out completely empty.
#
# shellcheck disable=SC2317,SC2329  # stubs are called by the sourced module
alert=$(
    log() { :; }
    check_external_access() { return 1; }   # force the outage branch
    sleep() { :; }
    send_slack_notification() { printf '%s|%s' "$1" "$2"; exit 0; }
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/health.d/20-cloudflared.sh"
)
assert_set "${alert%%|*}" "outage alert has a title"
assert_set "${alert##*|}" "outage alert has a body"

echo "config integrity guard (health-check-engine.sh):"

# Extracted so sourcing does not trigger a real health check run.
sed -n '/^check_config_integrity()/,/^}/p' "$ENGINE" > "$TMP/fn.sh"

# Prints "<alert>|<log output>" so both channels can be asserted on.
config_run() {   # $1 = config contents, or MISSING
    (
        alerts=""; logs=""
        # shellcheck disable=SC2317,SC2329  # both are called by the sourced function
        log() { logs="$logs$1"; }
        # shellcheck disable=SC2317,SC2329
        send_slack_notification() { alerts="$1"; }
        cf="$TMP/config.yml"
        if [ "$1" = "MISSING" ]; then rm -f "$cf"; else printf '%s\n' "$1" > "$cf"; fi
        # shellcheck source=/dev/null
        source "$TMP/fn.sh"
        # Repoint the hardcoded live path at the fixture.
        eval "$(declare -f check_config_integrity | sed "s|/home/goce/.cloudflared/config.yml|$cf|")"
        check_config_integrity
        printf '%s|%s' "$alerts" "$logs"
    )
}
config_alert() { local out; out=$(config_run "$1"); printf '%s' "${out%%|*}"; }
config_log()   { local out; out=$(config_run "$1"); printf '%s' "${out##*|}"; }

# The old version grep'd /etc/caddy/config.d/*.caddy, which does not exist on
# the host, so it could never fire. This case fails if it reverts to a no-op.
assert_set   "$(config_alert 'service: http://127.0.0.1:8080')" "127.0.0.1:8080 alarms"
assert_empty "$(config_alert 'service: http://localhost:8080')" "localhost:8080 stays quiet"
assert_set   "$(config_alert MISSING)"                          "missing config alarms"

# The healthy path must still say something. A check that is silent when it
# passes cannot be told apart in the log from a check that never ran, which is
# the ambiguity that hid the 2026-01-28 outage for eight months.
assert_set   "$(config_log 'service: http://localhost:8080')"   "healthy path logs a verdict"

echo "no 'local' outside a function (whole bug class):"

# Behavioural tests only catch the instances someone thought to write a case
# for. This is structural: bash refuses `local` at script top level, erroring
# and assigning nothing, which is how two separate @all alerts ended up being
# sent completely empty. Scans every health script so a third cannot appear.
top_level_local() {
    awk '
      /^[a-zA-Z_][a-zA-Z0-9_]*\(\)[[:space:]]*\{/ { fn=1; depth=1; next }
      fn && /\{/ { depth++ }
      fn && /\}/ { depth--; if (depth <= 0) fn=0 }
      /[[:space:]]local[[:space:]]/ && !fn { printf "%s:%d ", FILENAME, NR }
    ' "$1"
}

all_hits=""
for f in "$SCRIPT_DIR/enhanced-health-check.sh" "$SCRIPT_DIR/health-check-engine.sh" \
         "$SCRIPT_DIR"/health.d/*.sh; do
    [ -f "$f" ] || continue
    all_hits="$all_hits$(top_level_local "$f")"
done
if [ -n "$all_hits" ]; then
    fail "top-level 'local' found at: $all_hits"
else
    pass "no top-level 'local' in any health script"
fi

echo "HTTP probe + notification delivery (health-check-engine.sh):"

# A real server, so these assert on actual status codes rather than a mock.
# http.server answers 200 for an existing path, 404 for a missing one, and 501
# for POST, which covers every case below.
# -u is required: without it python buffers the "Serving HTTP on ... port N"
# banner and the port can never be read back.
( cd "$TMP" && exec python3 -u -m http.server 0 --bind 127.0.0.1 ) >"$TMP/srv.log" 2>&1 &
SRV_PID=$!
trap 'kill "$SRV_PID" 2>/dev/null; rm -rf "$TMP"' EXIT
PORT=""
for _ in $(seq 1 40); do
    PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$TMP/srv.log" | head -1)
    [ -n "$PORT" ] && break
    sleep 0.1
done

if [ -z "$PORT" ]; then
    fail "could not start local http.server (probe checks skipped)"
else
    echo "ok" > "$TMP/exists.txt"
    eval "$(sed -n '/^check_service_http()/,/^}/p' "$ENGINE")"

    # THE regression: the old version was `curl -s "$url" >/dev/null; return $?`,
    # which exits 0 for any response that arrives, so a 404 or a 502 read as
    # healthy and only a refused connection registered.
    if check_service_http "http://127.0.0.1:$PORT/exists.txt" 5; then
        pass "200 reads as up"
    else
        fail "200 reads as DOWN"
    fi
    if check_service_http "http://127.0.0.1:$PORT/no-such-file" 5; then
        fail "404 reads as UP (the regression is back)"
    else
        pass "404 reads as down"
    fi
    if check_service_http "http://127.0.0.1:1/" 2; then
        fail "refused connection reads as UP"
    else
        pass "refused connection reads as down"
    fi

    # Notification delivery: http.server rejects POST with 501, so a correct
    # implementation must report the failure rather than discard it.
    notify_out=$(
        SCRIPT_DIR="$TMP"
        printf 'http://127.0.0.1:%s/hook' "$PORT" > "$TMP/health_webhook_url"
        # shellcheck disable=SC2317,SC2329
        log() { printf "%s\n" "$1"; }
        eval "$(sed -n '/^send_slack_notification()/,/^}/p' "$ENGINE")"
        # Quotes and a backslash: string-interpolated JSON would be invalid here.
        send_slack_notification 'Title with "quotes"' 'body \ with "quotes" and \n' '🚨'
    )
    case "$notify_out" in
        *"FAILED to send"*) pass "non-200 webhook response is reported" ;;
        *)                  fail "webhook failure went unreported: [$notify_out]" ;;
    esac
    case "$notify_out" in
        *"could not encode"*) fail "quotes/backslashes broke JSON encoding" ;;
        *)                    pass "quotes and backslashes encode cleanly" ;;
    esac
fi

echo
if [ "$fails" -eq 0 ]; then
    echo "PASS"
else
    echo "FAILED: $fails assertion(s)"
    exit 1
fi
