#!/bin/bash
# Back up the Immich originals + DB dumps and /mnt/ssd/backups to the Terra
# (restic over WireGuard to an append-only rest-server). See terra/README.md
# Part B. Runs as root from backup-immich-terra.timer (04:00); exits non-zero
# on failure, which fires notify-failure@ via OnFailure=.
#
# /root/.config/restic/terra.pass  restic password (copy in Vaultwarden; lose
#                                  both and the Terra copy is unreadable)
# /root/.config/restic/terra.repo  rest:http://lemongrab:<pw>@10.8.0.4:8000/lemongrab/
# Seed run with the drive plugged into lemongrab: set RESTIC_REPOSITORY to the
# local path instead, e.g. RESTIC_REPOSITORY=/mnt/offsite/restic/lemongrab.
set -euo pipefail

# systemd runs this without HOME; restic needs it for its cache (log 2026-10-20).
export HOME="${HOME:-/root}"
export RESTIC_PASSWORD_FILE=/root/.config/restic/terra.pass
[ -n "${RESTIC_REPOSITORY:-}" ] || export RESTIC_REPOSITORY_FILE=/root/.config/restic/terra.repo

# thumbs/ and encoded-video/ are left out on purpose: Immich regenerates them.
lib=/mnt/ssd_1tb/immich-library
restic backup "$lib/library" "$lib/upload" "$lib/profile" "$lib/backups" /mnt/ssd/backups
