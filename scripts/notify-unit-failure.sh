#!/bin/bash
# Posts a Mattermost alert when a systemd unit fails. Invoked by
# notify-failure@.service, which units reference via OnFailure=.
#
# Why this exists: every alert in this homelab used to be emitted BY the health
# check script, so when that script stopped executing (203/EXEC, unquoted path
# with a space), the thing responsible for reporting the outage was the thing
# that was down. It failed hourly and silently from 2026-01-28 to 2026-09-25.
# systemd fires OnFailure= even when ExecStart never got off the ground, so this
# notifier survives the failure mode that hid the original one.
set -uo pipefail

UNIT="${1:-unknown}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WEBHOOK_URL=$(cat "$SCRIPT_DIR/health_webhook_url" 2>/dev/null || echo "")
if [ -z "$WEBHOOK_URL" ]; then
    echo "notify-unit-failure: no webhook at $SCRIPT_DIR/health_webhook_url" >&2
    exit 0
fi

RESULT=$(systemctl show -p Result --value "$UNIT" 2>/dev/null || echo "?")
EXITSTATUS=$(systemctl show -p ExecMainStatus --value "$UNIT" 2>/dev/null || echo "?")
# A 203/EXEC failure produces no journal output at all, so the exit status above
# is often the only evidence. Keep both.
LOGS=$(journalctl -u "$UNIT" -n 15 --no-pager -o cat 2>/dev/null | tail -15)

# JSON-encode via python rather than string interpolation: log lines routinely
# contain quotes and backslashes that would produce invalid JSON by hand.
python3 - "$WEBHOOK_URL" "$UNIT" "$RESULT" "$EXITSTATUS" "$LOGS" <<'PY'
import json, sys, urllib.request

url, unit, result, exitstatus, logs = sys.argv[1:6]
hint = ""
if exitstatus == "203":
    hint = "\n_203/EXEC means systemd could not execute the binary: check the ExecStart path (unquoted spaces) and the executable bit._"

text = (
    f"🚨 **systemd unit failed: {unit}**\n"
    f"Result: `{result}` · ExecMainStatus: `{exitstatus}`{hint}\n"
    f"```\n{logs.strip() or '(no journal output)'}\n```"
)
req = urllib.request.Request(
    url,
    data=json.dumps({"text": text}).encode(),
    headers={"Content-Type": "application/json"},
)
try:
    urllib.request.urlopen(req, timeout=10)
except Exception as e:
    sys.exit(f"notify-unit-failure: POST failed: {e}")
PY
