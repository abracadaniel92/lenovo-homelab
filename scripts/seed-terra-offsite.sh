#!/bin/bash
# One-off: seed the Terra's restic repo over USB on lemongrab, so the first
# ~135 GB never crosses the home upload (terra/README.md, log 2026-10-17).
# Formats the Toshiba (only on the first run), creates the restic password and
# repo, runs the first backup, checks it, unmounts, and pushes to the phone.
# Safe to rerun: an existing password/repo is reused and the backup resumes.
# Runs itself inside tmux session "seed" so a dropped SSH doesn't kill it.
set -euo pipefail
[ -n "${TMUX:-}" ] || exec tmux new -A -s seed "$0"
[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

disk=/dev/disk/by-id/ata-TOSHIBA_MQ04ABD200_56HRP1HST
part=$disk-part1
mnt=/mnt/offsite
repo=$mnt/restic/lemongrab
pass=/root/.config/restic/terra.pass
here=$(dirname "$(readlink -f "$0")")
done_msg() { echo; echo "$1"; "$here/ntfy-push.sh" "$1" || true; read -rp "Press Enter to close."; }
trap 'done_msg "Terra seed FAILED, check tmux session seed"' ERR

[ -e "$disk" ] || { echo "Toshiba not plugged in ($disk)"; exit 1; }
apt-get install -y restic parted

if [ ! -s "$pass" ]; then
    install -d -m 700 "$(dirname "$pass")"
    (umask 077; openssl rand -base64 32 > "$pass")
fi
echo; echo "Restic password (save it in Vaultwarden, without it the backup is unreadable):"
cat "$pass"; echo
read -rp "Saved it in Vaultwarden? Type yes: " ok
[ "$ok" = yes ] || { echo "Stopped."; exit 1; }

if [ "$(blkid -s LABEL -o value "$part" 2>/dev/null)" != offsite ]; then
    read -rp "This ERASES the Toshiba 2 TB drive. Type erase: " ok
    [ "$ok" = erase ] || { echo "Stopped."; exit 1; }
    umount "$part" 2>/dev/null || true
    parted -s "$disk" mklabel gpt mkpart offsite ext4 0% 100%
    udevadm settle
    mkfs.ext4 -F -L offsite "$part"
fi
mkdir -p "$mnt"
mountpoint -q "$mnt" || mount "$part" "$mnt"

export RESTIC_PASSWORD_FILE=$pass
[ -f "$repo/config" ] || restic -r "$repo" init
RESTIC_REPOSITORY=$repo "$here/backup-immich-terra.sh"
restic -r "$repo" check
restic -r "$repo" snapshots
umount "$mnt"
trap - ERR
done_msg "Terra seed done, drive unmounted, safe to unplug"
