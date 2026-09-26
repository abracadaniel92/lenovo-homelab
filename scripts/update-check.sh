#!/bin/bash
# Weekly "which images have updates" push: update-check.sh [--print]
# Compares each running container's image digest with the registry's current
# digest for the same tag. Nothing is pulled or restarted: updating stays a
# manual, one-service-at-a-time job (.cursor/skills/update-homelab-service).
# Run by update-check.timer (scripts/setup-update-check-timer.sh).
# --print shows the result instead of pushing it.
#
# ponytail: only detects a moved tag. Pinned tags (vaultwarden:1.37.3,
# nextcloud:30-apache, cal.com:v6.2.0) never move, so newer releases of those
# are invisible here, and a patch looks the same as a major jump (jellyfin
# :latest moving 10.x -> 12.x). Always read release notes before pulling.
# Upgrade path: a GitHub-releases lookup per pinned image, or Renovate.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
newer=() unchecked=()

for ref in $(docker ps --format '{{.Image}}' | sort -u); do
    [[ "$ref" == *:* ]] || continue                       # bare image IDs, untagged local builds
    have=$(docker image inspect -f '{{join .RepoDigests " "}}' "$ref" 2>/dev/null)
    [ -n "$have" ] || continue                           # built locally, never pulled
    want=$(timeout 30 docker buildx imagetools inspect "$ref" --format '{{json .Manifest.Digest}}' 2>&1 | tr -d '"')
    case "$want" in
        sha256:*) [[ "$have" == *"$want"* ]] || newer+=("${ref##*/}") ;;
        *"does not exist"*) ;;                           # local build (paperless-webserver:local)
        *) unchecked+=("${ref##*/}") ;;                  # registry down or rate-limited (Docker Hub 429)
    esac
done

[ ${#newer[@]} -gt 0 ] || [ ${#unchecked[@]} -gt 0 ] || { [ "${1:-}" = --print ] && echo "all up to date"; exit 0; }

title="📦 Image updates: ${newer[*]:-none}"
[ ${#unchecked[@]} -eq 0 ] || title+=" | could not check: ${unchecked[*]}"

if [ "${1:-}" = --print ]; then echo "$title"; else NTFY_PRIORITY=default "$SCRIPT_DIR/ntfy-push.sh" "$title"; fi
