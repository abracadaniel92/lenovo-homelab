#!/bin/bash
###############################################################################
# One-off: encrypt the B2 offsite copies and put the sync under systemd.
#
#   sudo bash scripts/setup-b2-encrypted-sync.sh
#
# Context: docs/reference/troubleshooting-log.md, entry 2026-09-26 (Backblaze
# offsite audit). Fixes all three gaps it found:
#   1. sync ran off bare user cron, failures were silent
#      -> systemd timer with OnFailure=notify-failure@, cron line removed
#   2. archives uploaded unencrypted (TravelSync holds live Google OAuth creds)
#      -> rclone crypt remote b2-crypt over a NEW bucket Goce-Lenovo-crypt
#   3. unbounded growth
#      -> sync script prunes superseded/ after 90 days; bucket lifecycle
#         deletes hidden (overwritten/moved) versions after 1 day
# The matching health check is health.d/60-offsite-freshness.sh, which switches
# itself on once the timer below is enabled.
#
# NOT touched: the old plaintext buckets Goce-Lenovo and Goce-Lenovo-superseded.
# They stay as a fallback until you have saved the crypt key off this box.
# Deleting them is a separate, manual step (printed at the end).
#
# Idempotent: safe to re-run. An existing b2-crypt remote is reused, never
# regenerated (a new key would orphan everything already uploaded).
###############################################################################
set -uo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root: sudo bash $0"
    exit 1
fi

LINK="/opt/homelab"
RCLONE_USER="goce"
BUCKET="b2-backup:Goce-Lenovo-crypt"
rc() { sudo -u "$RCLONE_USER" rclone "$@"; }
ok() { echo "✅ $1"; }
skip() { echo "•  $1"; }
die() { echo "❌ $1"; exit 1; }

[ -f "$LINK/scripts/sync-backups-to-b2.sh" ] || die "$LINK/scripts/sync-backups-to-b2.sh missing"
grep -q 'b2-crypt:current' "$LINK/scripts/sync-backups-to-b2.sh" \
    || die "$LINK is on a branch without the encrypted sync script (check git branch)"

echo "=== 1. Encrypted bucket + crypt remote ==="
if rc listremotes | grep -qx 'b2-crypt:'; then
    skip "b2-crypt remote already exists, reusing its key"
else
    rc mkdir "$BUCKET" || die "could not create bucket $BUCKET (does the B2 key allow bucket creation?)"
    # Two random passwords (content key + salt). Output suppressed: rclone
    # echoes the config, and the key should not land in a terminal log.
    rc config create b2-crypt crypt \
        remote="$BUCKET" \
        filename_encryption=standard \
        directory_name_encryption=true \
        password="$(openssl rand -base64 32)" \
        password2="$(openssl rand -base64 32)" \
        --obscure >/dev/null || die "rclone config create failed"
    ok "created b2-crypt -> $BUCKET"
fi

echo "=== 2. Lifecycle: delete hidden versions after 1 day ==="
# B2 never truly deletes by default: every file rclone moves into superseded/
# or prunes leaves a hidden version in the bucket forever. This rule only
# affects versions that are ALREADY hidden (deleted/replaced), never the
# current files. rclone can only set this bucket-wide, which is what we want.
rc backend lifecycle "$BUCKET" -o daysFromHidingToDeleting=1 >/dev/null || die "could not set lifecycle rule"
ok "lifecycle rule set on $BUCKET"

echo "=== 3. Deploy sync script ==="
install -m 0755 "$LINK/scripts/sync-backups-to-b2.sh" /usr/local/bin/sync-backups-to-b2.sh
touch /var/log/rclone-sync.log && chown "$RCLONE_USER" /var/log/rclone-sync.log
ok "/usr/local/bin/sync-backups-to-b2.sh now targets b2-crypt"

echo "=== 4. systemd service + timer ==="
cat > /etc/systemd/system/sync-backups-to-b2.service <<'EOF'
[Unit]
Description=Sync local backups to Backblaze B2 (encrypted)
# Was a bare `0 3 * * *` user cron line until 2026-09-26: a failed sync was
# silent. As a unit it inherits the failure notifier and shows in list-timers.
OnFailure=notify-failure@%n.service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
# rclone's config (incl. the crypt key) lives in goce's home.
User=goce
ExecStart=/usr/local/bin/sync-backups-to-b2.sh
# A hung upload is not a failure, so OnFailure= would never fire.
TimeoutStartSec=4h
EOF
cat > /etc/systemd/system/sync-backups-to-b2.timer <<'EOF'
[Unit]
Description=Daily B2 offsite sync, after the 02:00 local backups

[Timer]
OnCalendar=*-*-* 03:00:00
# Run at next boot if the box was off at 03:00.
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now sync-backups-to-b2.timer >/dev/null 2>&1 || die "could not enable timer"
ok "sync-backups-to-b2.timer enabled"

echo "=== 5. Remove the old cron line (or the sync runs twice) ==="
if crontab -u "$RCLONE_USER" -l 2>/dev/null | grep -q 'sync-backups-to-b2.sh'; then
    crontab -u "$RCLONE_USER" -l > "/home/$RCLONE_USER/crontab.bak-$(date +%Y%m%d-%H%M%S)"
    crontab -u "$RCLONE_USER" -l | grep -v 'sync-backups-to-b2.sh' | crontab -u "$RCLONE_USER" -
    ok "removed from $RCLONE_USER crontab (backup in /home/$RCLONE_USER/crontab.bak-*)"
else
    skip "no cron line for the sync"
fi

echo "=== 6. First encrypted upload (a few minutes for ~450 MiB) ==="
systemctl start sync-backups-to-b2.service
RESULT=$(systemctl show -p Result --value sync-backups-to-b2.service)
[ "$RESULT" = "success" ] || die "sync failed ($RESULT): journalctl -u sync-backups-to-b2.service; tail /var/log/rclone-sync.log"
ok "sync ran clean"

echo "=== 7. Verify ==="
# Round trip: download the newest Vaultwarden archive through the crypt layer
# and compare it byte for byte with the local copy.
# shellcheck disable=SC2012  # engine-generated timestamp names
LOCAL=$(ls -t /mnt/ssd/backups/vaultwarden/vaultwarden-*.tar.gz | head -1)
TMPD=$(sudo -u "$RCLONE_USER" mktemp -d)
if rc copy "b2-crypt:current/vaultwarden/$(basename "$LOCAL")" "$TMPD/" \
    && cmp -s "$LOCAL" "$TMPD/$(basename "$LOCAL")"; then
    rm -rf "$TMPD"
    ok "round trip OK: $(basename "$LOCAL") decrypts identical to local"
else
    rm -rf "$TMPD"
    die "round trip FAILED for $(basename "$LOCAL")"
fi

# What Backblaze sees must be ciphertext, names included.
if rc lsf -R "$BUCKET" | grep -qiE 'vaultwarden|travelsync|nextcloud|tar\.gz'; then
    die "plaintext names visible in $BUCKET"
fi
ok "raw bucket shows only encrypted names"

# The health module is now active; run it once so a problem shows up now.
"$LINK/scripts/health-check-engine.sh" >/dev/null 2>&1
grep 'Offsite freshness\|offsite' /var/log/enhanced-health-check.log | tail -1

cat <<EOF

=====================================================================
⚠️  DO THIS NOW: save the encryption key OFF this machine.
    If lemongrab dies and the key only lived here, every offsite copy
    is unreadable. Run this in your own terminal (not through Claude,
    so the key stays out of any transcript):

      rclone config show b2-crypt
      rclone reveal <password value>     # repeat for password2

    Store both, plus 'filename_encryption = standard' and the bucket
    name Goce-Lenovo-crypt, as a Vaultwarden secure note AND on paper.

    To restore on a fresh machine: rclone config create b2-crypt crypt
    remote=<b2 remote>:Goce-Lenovo-crypt password=... password2=...
    --obscure, then: rclone copy b2-crypt:current/<service>/ ./

Then, and only then, the old plaintext buckets can go:
      rclone purge b2-backup:Goce-Lenovo
      rclone purge b2-backup:Goce-Lenovo-superseded
=====================================================================
EOF
