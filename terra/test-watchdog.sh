#!/bin/bash
# Self-check for watchdog.sh, runnable anywhere: bash terra/test-watchdog.sh
# Fakes ntfy with a local listener and checks which alerts fire.
set -uo pipefail
cd "$(dirname "$0")" || exit 1
tmp=$(mktemp -d); trap 'kill $srv 2>/dev/null; rm -rf "$tmp"' EXIT

python3 - "$tmp/posts" <<'EOF' &
import sys, http.server
out = sys.argv[1]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers['Content-Length'])).decode()
        open(out, 'a').write(body + '\n'); self.send_response(200); self.end_headers()
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', 18765), H).serve_forever()
EOF
srv=$!; sleep 1
echo http://127.0.0.1:18765/t > "$tmp/topic"
mkdir -p "$tmp/snaps"

run() { TOPIC_FILE="$tmp/topic" SNAP_DIR="$tmp/snaps" STATE="$tmp/state" \
        SITE=http://127.0.0.1:1 LEMONGRAB_WG="$1" bash watchdog.sh 2>/dev/null; }
fail=0
check() { if grep -q "$1" "$tmp/posts" 2>/dev/null; then echo "  ok: $2"; else echo "  FAIL: $2"; fail=1; fi; }

# ponytail: the site is faked as down (closed port), so each run takes ~60 s of curl retries.
run 127.0.0.1                              # site down, "WireGuard" up, no snapshots
check "^gmojsoski.com down" "site down alone is told apart"
check "^No new lemongrab backup" "stale snapshots alert"
run 192.0.2.1                              # site down, WireGuard unreachable
check "^lemongrab offline" "both down reads as home offline"
n=$(wc -l < "$tmp/posts"); run 192.0.2.1
if [ "$(wc -l < "$tmp/posts")" = "$n" ]; then echo "  ok: repeat run is deduped"; else echo "  FAIL: dedup"; fail=1; fi

if [ $fail = 0 ]; then echo PASS; else echo FAIL; exit 1; fi
