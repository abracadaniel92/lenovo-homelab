#!/bin/bash
# Terra stage 3 (README Part A steps 1-2, 4, 6): mount the seeded offsite
# drive, start rest-server on the WireGuard IP, install the watchdog.
# Run on the Terra from the repo root, in a real terminal (it prompts):
#   sudo bash terra/setup-offsite.sh
# Safe to re-run. Never formats or writes restic data: the repo on the drive
# was seeded on lemongrab (log 2026-10-17); only its owner is changed.
set -euo pipefail
cd "$(dirname "$0")"

DISK=/dev/disk/by-id/ata-TOSHIBA_MQ04ABD200_56HRP1HST
UUID=0bf3f4b3-60ac-472e-a054-fc45a39629a8
MNT=/mnt/offsite
PASS_FILE=/root/rest-server-lemongrab.pass

[ "$(blkid -s LABEL -o value "$DISK-part1")" = offsite ] \
    || { echo "$DISK-part1 is not labelled 'offsite'; stopping" >&2; exit 1; }

apt-get update
apt-get install -y hdparm restic-rest-server apache2-utils

echo "== SMART baseline"
smartctl -H -A "$DISK" || smartctl -d sat -H -A "$DISK" || true

# Mount by UUID. nofail: a missing USB drive must not hang boot.
mkdir -p "$MNT"
grep -q "$UUID" /etc/fstab \
    || echo "UUID=$UUID $MNT ext4 defaults,noatime,nofail,x-systemd.device-timeout=30s 0 2" >> /etc/fstab
systemctl daemon-reload
mountpoint -q "$MNT" || mount "$MNT"
mountpoint -q "$MNT" || { echo "$MNT did not mount; stopping" >&2; exit 1; }
[ -f "$MNT/restic/lemongrab/config" ] \
    || { echo "no seeded repo at $MNT/restic/lemongrab; stopping" >&2; exit 1; }

# Laptop HDD parks its heads aggressively; APM resets on power loss.
hdparm -B 254 "$DISK" || echo "WARN: hdparm -B unsupported via the enclosure; watch Load_Cycle_Count"
grep -qF "$DISK" /etc/hdparm.conf || printf '\n%s {\n\tapm = 254\n}\n' "$DISK" >> /etc/hdparm.conf
# hdparm.conf skips USB disks; this rule re-applies APM on every hotplug.
install -m 0644 "$(dirname "$0")/99-offsite-apm.rules" /etc/udev/rules.d/
udevadm control --reload
# Every SMART poll is a drive access that unparks the heads; 3 h, not 30 min.
grep -q '^smartd_opts=' /etc/default/smartmontools \
    || echo 'smartd_opts="--interval=10800"' >> /etc/default/smartmontools
systemctl restart smartmontools

# rest-server: append-only, WireGuard IP only, never without the drive.
cat > /etc/default/restic-rest-server <<'EOF'
# Managed by terra/setup-offsite.sh (lenovo-homelab repo).
LISTEN = 10.8.0.4:8000
BACKUP_DIR = /mnt/offsite/restic
ARGS = "--append-only --private-repos --htpasswd-file /etc/restic-rest-server/users.htpasswd"
EOF
mkdir -p /etc/systemd/system/restic-rest-server.service.d
cat > /etc/systemd/system/restic-rest-server.service.d/override.conf <<'EOF'
[Unit]
Wants=wg-quick@wg0.service
After=wg-quick@wg0.service
RequiresMountsFor=/mnt/offsite
# A manual umount or a yanked cable doesn't stop Requires= dependents
# (unplug test, log 2026-10-21); BindsTo= does.
BindsTo=mnt-offsite.mount
EOF

if ! grep -q '^lemongrab:' /etc/restic-rest-server/users.htpasswd; then
    (umask 077; openssl rand -base64 24 | tr -d '/+=' > "$PASS_FILE")
    htpasswd -iB /etc/restic-rest-server/users.htpasswd lemongrab < "$PASS_FILE"
fi
chown -R restic-rest-server:restic-rest-server "$MNT/restic"
systemctl daemon-reload
systemctl enable restic-rest-server
systemctl restart restic-rest-server

# Watchdog: lemongrab offline / no new snapshot in 36 h -> phone.
install -m 0755 watchdog.sh /usr/local/bin/terra-watchdog.sh
install -d -m 0700 /etc/terra-watchdog
if [ ! -s /etc/terra-watchdog/ntfy_topic_url ]; then
    read -rp "ntfy topic URL (same one lemongrab uses): " url
    (umask 077; echo "$url" > /etc/terra-watchdog/ntfy_topic_url)
fi
cat > /etc/systemd/system/terra-watchdog.service <<'EOF'
[Unit]
Description=Terra watchdog: alert when lemongrab or its backups go quiet
After=network-online.target wg-quick@wg0.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/terra-watchdog.sh
EOF
cat > /etc/systemd/system/terra-watchdog.timer <<'EOF'
[Unit]
Description=Run the Terra watchdog every 10 min

[Timer]
OnBootSec=5min
OnUnitActiveSec=10min

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now terra-watchdog.timer

echo
echo "== Check"
ss -tlnp | grep ':8000' || echo "WARN: nothing listening on 8000"
systemctl is-active restic-rest-server terra-watchdog.timer || true
echo
echo "Done. lemongrab's rest-server password is in $PASS_FILE (root only)."
echo "Read it yourself (sudo cat $PASS_FILE), save it in Vaultwarden, then delete the file."
