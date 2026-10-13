#!/bin/bash
# Copy the live compose files of stacks that run outside the repo into
# docker/<name>/docker-compose.yml, so the repo matches what actually runs.
# Run on lemongrab: /opt/homelab/scripts/mirror-live-compose.sh
# Then review `git diff` BEFORE committing: the repo is PUBLIC.
# Secrets belong in each live stack's .env (gitignored), never inline.
#
# ponytail: fixed stack list. A new stack outside the repo needs adding here;
# `docker ps -a --format '{{.Label "com.docker.compose.project.working_dir"}}'`
# lists them all.
set -euo pipefail

REPO=/opt/homelab
STACKS=(
    /home/docker-projects/{authelia,DocumentsToCalendar-1,homepage,kitchenowl,linkwarden,mosquitto}
    /home/docker-projects/{nginx-vaultwarden,goatcounter,jellyfin,paperless,portainer,travelsync,uptime-kuma,vaultwarden}
    /home/apps/nextcloud
)

for d in "${STACKS[@]}"; do
    n=$(basename "$d")
    mkdir -p "$REPO/docker/$n"
    cp "$d/docker-compose.yml" "$REPO/docker/$n/docker-compose.yml"
done

cd "$REPO"
git status --short docker
echo
echo "Inline values on secret-looking keys (should print nothing):"
# shellcheck disable=SC2016  # '${' is a literal: skip ${VAR} references
{ git diff -U0 docker; git ls-files --others --exclude-standard docker | xargs -r cat; } |
    grep -iE '(pass|secret|token|key)[a-z_]*\s*[:=]\s*[^$ ]' | grep -vF '${' || echo "(none)"
