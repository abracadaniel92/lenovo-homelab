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
    ps) printf '%s\n' ${STUB_IMAGES} ;;
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
STUB_IMAGES="postgres:16 cf78e76683b9 local-build:dev"
check "nothing moved = no push" "$("$CHECK" --print)" "all up to date"

STUB_IMAGES="caddy:latest postgres:16 postgres:16 cf78e76683b9 local-build:dev mine:local ghcr.io/x/app:1"
check "moved tag listed, same digest and local builds skipped, 429 reported" \
    "$("$CHECK" --print)" "📦 Image updates: caddy:latest | could not check: app:1"

if [ "$fail" -eq 0 ]; then echo "PASS"; else echo "FAILED"; exit 1; fi
