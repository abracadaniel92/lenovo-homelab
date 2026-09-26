#!/bin/bash
# Self-check for ntfy-push.sh. Run directly: bash scripts/test-ntfy-push.sh
# curl is replaced by a stub on PATH that records calls, so nothing is sent.
set -uo pipefail

PUSH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/ntfy-push.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
# shellcheck disable=SC2016  # $* and $CURL_EXIT expand inside the stub, not here
printf '#!/bin/bash\necho "$*" >> "%s/calls"\nexit ${CURL_EXIT:-0}\n' "$TMP" > "$TMP/bin/curl"
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH" NTFY_TOPIC_FILE="$TMP/topic" NTFY_STATE_DIR="$TMP/state"

calls() { [ -f "$TMP/calls" ] && wc -l < "$TMP/calls" || echo 0; }
fail=0
check() {
    if [ "$2" = "$3" ]; then echo "  ok: $1"; else echo "  FAIL: $1 (expected '$3', got '$2')"; fail=1; fi
}

echo "ntfy-push:"
"$PUSH" "🚨 A"; rc=$?
check "no topic file = no push, exit 0" "$(calls) $rc" "0 0"

echo "https://ntfy.sh/test-topic" > "$TMP/topic"
"$PUSH" "🚨 A"
check "first alert is pushed"            "$(calls)" "1"
check "only the title is sent"           "$(grep -c -- '-d 🚨 A https://ntfy.sh/test-topic' "$TMP/calls")" "1"
"$PUSH" "🚨 A"
check "same title within window deduped" "$(calls)" "1"
"$PUSH" "🚨 B"
check "different title is pushed"        "$(calls)" "2"
NTFY_DEDUP_MINUTES=0 "$PUSH" "🚨 A"
check "same title after window pushed"   "$(calls)" "3"

CURL_EXIT=22 "$PUSH" "🚨 C" 2>/dev/null
check "failed POST exits non-zero"       "$?" "1"
CURL_EXIT=0 "$PUSH" "🚨 C"
check "failed POST is retried next run"  "$(calls)" "5"

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; exit 1; fi
