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
# ponytail: stubs log()/send_slack_notification() and asserts on what would have
# been sent. Ceiling: it does not exercise curl, docker or systemd, so it proves
# the alerting logic, not the probes. Upgrade path is a container fixture, which
# is not worth it for four assertions.
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

config_alert() {   # $1 = config contents, or MISSING
    (
        alerts=""
        # shellcheck disable=SC2317,SC2329  # both are called by the sourced function
        log() { :; }
        # shellcheck disable=SC2317,SC2329
        send_slack_notification() { alerts="$1"; }
        cf="$TMP/config.yml"
        if [ "$1" = "MISSING" ]; then rm -f "$cf"; else printf '%s\n' "$1" > "$cf"; fi
        # shellcheck source=/dev/null
        source "$TMP/fn.sh"
        # Repoint the hardcoded live path at the fixture.
        eval "$(declare -f check_config_integrity | sed "s|/home/goce/.cloudflared/config.yml|$cf|")"
        check_config_integrity
        printf '%s' "$alerts"
    )
}

# The old version grep'd /etc/caddy/config.d/*.caddy, which does not exist on
# the host, so it could never fire. This case fails if it reverts to a no-op.
assert_set   "$(config_alert 'service: http://127.0.0.1:8080')" "127.0.0.1:8080 alarms"
assert_empty "$(config_alert 'service: http://localhost:8080')" "localhost:8080 stays quiet"
assert_set   "$(config_alert MISSING)"                          "missing config alarms"

echo
if [ "$fails" -eq 0 ]; then
    echo "PASS"
else
    echo "FAILED: $fails assertion(s)"
    exit 1
fi
