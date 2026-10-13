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
declare -A names                                         # image ref -> its container names
while read -r img name; do names[$img]+="${names[$img]:+, }$name"; done < <(docker ps --format '{{.Image}} {{.Names}}')

for ref in $(printf '%s\n' "${!names[@]}" | sort); do
    [[ "$ref" == *:* ]] || continue                       # bare image IDs, untagged local builds
    have=$(docker image inspect -f '{{join .RepoDigests " "}}' "$ref" 2>/dev/null)
    [ -n "$have" ] || continue                           # built locally, never pulled
    want=$(timeout 30 docker buildx imagetools inspect "$ref" --format '{{json .Manifest.Digest}}' 2>&1 | tr -d '"')
    case "$want" in
        sha256:*) [[ "$have" == *"$want"* ]] || newer+=("• ${names[$ref]} (${ref##*/})") ;;
        *"does not exist"*) ;;                           # local build (paperless-webserver:local)
        *) unchecked+=("• ${names[$ref]} (${ref##*/})") ;;   # registry down or rate-limited (Docker Hub 429)
    esac
done

[ ${#newer[@]} -gt 0 ] || [ ${#unchecked[@]} -gt 0 ] || { [ "${1:-}" = --print ] && echo "all up to date"; exit 0; }

msg="📦 ${#newer[@]} container(s) have a newer image"
[ ${#newer[@]} -eq 0 ] || msg+=$'\n\nUpdate:\n'"$(printf '%s\n' "${newer[@]}")"
[ ${#unchecked[@]} -eq 0 ] || msg+=$'\n\nCould not check (registry busy, retry with update-check.sh --print):\n'"$(printf '%s\n' "${unchecked[@]}")"
msg+=$'\n\nNext: one at a time, read release notes, follow the update-homelab-service runbook. Pinned versions are not checked.'

if [ "${1:-}" = --print ]; then echo "$msg"; else NTFY_PRIORITY=default "$SCRIPT_DIR/ntfy-push.sh" "$msg"; fi
