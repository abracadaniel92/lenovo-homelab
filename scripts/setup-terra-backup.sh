#!/bin/bash
# One-off: finish terra/README.md Part B on lemongrab. Run as root:
#   sudo bash /opt/homelab/scripts/setup-terra-backup.sh
# Writes /root/.config/restic/terra.repo (rest-server URL with the `lemongrab`
# password from Vaultwarden), proves restic can read the repo, installs
# backup-immich-terra.{service,timer}, enables the timer and starts a first run.
# Safe to re-run.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

cfg=/root/.config/restic
[ -s "$cfg/terra.pass" ] || { echo "missing $cfg/terra.pass (made by the seed)"; exit 1; }

if [ ! -s "$cfg/terra.repo" ]; then
    read -rsp "rest-server password for user lemongrab (Vaultwarden): " pw; echo
    # Percent-encode: a raw @ : / or % in the password would break the URL.
    enc=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$pw")
    (umask 077; echo "rest:http://lemongrab:${enc}@10.8.0.4:8000/lemongrab/" > "$cfg/terra.repo")
fi

echo "Checking the repo..."
RESTIC_PASSWORD_FILE="$cfg/terra.pass" RESTIC_REPOSITORY_FILE="$cfg/terra.repo" \
    restic snapshots --no-lock --latest 1 \
    || { echo "restic could not read the repo; fix $cfg/terra.repo (delete it to re-enter the password)"; exit 1; }

install -m 0644 /opt/homelab/systemd/backup-immich-terra.service /opt/homelab/systemd/backup-immich-terra.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now backup-immich-terra.timer
systemctl start --no-block backup-immich-terra.service
echo "OK. First run started: journalctl -fu backup-immich-terra"
