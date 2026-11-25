#!/bin/bash
# Self-check for update-check.sh. Run directly: bash scripts/test-update-check.sh
# docker is replaced by a stub on PATH, so no registry is contacted.
set -uo pipefail

CHECK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/update-check.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/docker" <<'EOF'
#!/bin/bash
# ps -> running images; image inspect -> local digests; buildx -> registry digests
case "$1" in
    ps) printf '%s\n' "$STUB_IMAGES" ;;   # "image name" per line
    image) case "${@: -1}" in
        caddy:latest) echo "caddy@sha256:old" ;;
        postgres:16) echo "postgres@sha256:same" ;;
        ghcr.io/x/app:1) echo "ghcr.io/x/app@sha256:a" ;;
        mine:local) echo "mine@sha256:b" ;;
        esac ;;
    buildx) case "$4" in
        caddy:latest) echo '"sha256:new"' ;;
        postgres:16) echo '"sha256:same"' ;;
        mine:local) echo "ERROR: pull access denied, repository does not exist" >&2; exit 1 ;;
        *) echo "ERROR: 429 Too Many Requests" >&2; exit 1 ;;
        esac ;;
esac
EOF
chmod +x "$TMP/bin/docker"
export PATH="$TMP/bin:$PATH" STUB_IMAGES

fail=0
check() {
    if [ "$2" = "$3" ]; then echo "  ok: $1"; else echo "  FAIL: $1 (expected '$3', got '$2')"; fail=1; fi
}

echo "update-check:"
NEXT=$'\n\nNext: one at a time, read release notes, follow the update-homelab-service runbook. Pinned versions are not checked.'
STUB_IMAGES=$'postgres:16 db\nlocal-build:dev lb\ntravelsync-app ts'
check "nothing moved, untagged local build not flagged" "$("$CHECK" --print)" "all up to date"

STUB_IMAGES=$'caddy:latest caddy\npostgres:16 db1\npostgres:16 db2\ncf78e76683b9 stale\nmine:local m\nghcr.io/x/app:1 app\ntravelsync-app ts'
check "moved tag + bare image ID listed, same digest and local builds skipped, 429 reported" \
    "$("$CHECK" --print)" "📦 2 container(s) have a newer image

Update:
• caddy (caddy:latest)
• stale (newer image already here: docker compose up -d --force-recreate)

Could not check (registry busy, retry with update-check.sh --print):
• app (app:1)$NEXT"

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; exit 1; fi
