#!/bin/bash
###############################################################################
# One-off repair: re-arm the automation layer that died on 2026-01-28.
#
#   sudo bash scripts/repair-silent-failures.sh
#
# Context: docs/reference/troubleshooting-log.md, entry 2026-09-25.
# Three systems broke on the same day because an unquoted path containing a
# space stopped resolving:
#   - enhanced-health-check.service  203/EXEC hourly since 2026-01-28
#   - backup cron in /etc/crontab    never executed since 2026-01-17
#   - healthcheck-watchdog.sh        referenced every 5min, file does not exist
#
# Strategy: introduce a space-free /opt/homelab symlink and point everything at
# it, so this bug class cannot recur, then attach an out-of-band failure
# notifier so the next silent death is loud within minutes instead of months.
#
# Existing unit files are NOT edited. Changes go in drop-ins, because
# systemd/ is read-only core per CLAUDE.md.
#
# ⚠️ Re-arms auto-recovery: once the health check runs again it will restart
# Caddy and cloudflared on its own if it judges them down.
#
# Idempotent: safe to re-run.
###############################################################################
set -uo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "❌ Must run as root: sudo bash $0"
    exit 1
fi

REPO="/home/goce/Desktop/Cursor projects/Pi-version-control"
LINK="/opt/homelab"
ok() { echo "✅ $1"; }
skip() { echo "•  $1"; }

echo "=== 1. Space-free path ==="
if [ -L "$LINK" ] && [ "$(readlink -f "$LINK")" = "$(readlink -f "$REPO")" ]; then
    skip "$LINK already points at the repo"
else
    ln -sfn "$REPO" "$LINK"
    ok "$LINK -> $REPO"
fi
# Fail loudly rather than writing units that point at a broken link.
[ -x "$LINK/scripts/health-check-engine.sh" ] || { echo "❌ $LINK/scripts/health-check-engine.sh not executable"; exit 1; }

echo "=== 2. Failure notifier ==="
install -m 0644 "$LINK/systemd/notify-failure@.service" /etc/systemd/system/notify-failure@.service
ok "installed notify-failure@.service"

echo "=== 3. Fix health check ExecStart + attach notifier ==="
# ExecStart is reset to empty first; without that systemd appends a second
# command to a Type=oneshot unit instead of replacing the broken one.
mkdir -p /etc/systemd/system/enhanced-health-check.service.d
cat > /etc/systemd/system/enhanced-health-check.service.d/override.conf <<EOF
[Unit]
OnFailure=notify-failure@%n.service

[Service]
ExecStart=
ExecStart=$LINK/scripts/health-check-engine.sh
EOF
ok "drop-in written (original unit file untouched)"

echo "=== 4. Attach notifier to the other scheduled units ==="
for unit in hdd-health-check.service slack-goatcounter-weekly.service portfolio-update.service; do
    if systemctl cat "$unit" >/dev/null 2>&1; then
        mkdir -p "/etc/systemd/system/${unit}.d"
        printf '[Unit]\nOnFailure=notify-failure@%%n.service\n' > "/etc/systemd/system/${unit}.d/onfailure.conf"
        ok "notifier attached to $unit"
    else
        skip "$unit not present"
    fi
done

echo "=== 5. Repair /etc/crontab ==="
cp /etc/crontab "/etc/crontab.bak-$(date +%Y%m%d-%H%M%S)"
# The backup line broke on the unquoted space: cron handed bash
# "/home/goce/Desktop/Cursor" and the redirect target parsed as the same bare
# word, which is what created the stray zero-byte ~/Desktop/Cursor file.
if grep -q 'backup-all-critical.sh' /etc/crontab; then
    sed -i '\#backup-all-critical\.sh#d' /etc/crontab
fi
echo "0 2 * * * goce bash $LINK/scripts/backup-all-critical.sh >> $LINK/logs/backup-all-critical.log 2>&1" >> /etc/crontab
ok "backup cron rewritten via $LINK (no spaces)"

# Cron has invoked this missing file every 5 minutes. Drop the line; if the
# watchdog is wanted back it needs to be written first, then re-added.
if grep -q 'healthcheck-watchdog.sh' /etc/crontab && [ ! -x /usr/local/bin/healthcheck-watchdog.sh ]; then
    sed -i '\#healthcheck-watchdog\.sh#d' /etc/crontab
    ok "removed cron line for missing healthcheck-watchdog.sh"
fi

echo "=== 6. Deploy B2 sync with --backup-dir ==="
install -m 0755 "$LINK/scripts/sync-backups-to-b2.sh" /usr/local/bin/sync-backups-to-b2.sh
ok "offsite sync is now an archive, not a mirror"

echo "=== 7. Reload and enable ==="
systemctl daemon-reload
systemctl enable --now enhanced-health-check.timer >/dev/null 2>&1 && ok "enhanced-health-check.timer enabled"
systemctl reset-failed enhanced-health-check.service 2>/dev/null

echo
echo "=== VERIFY ==="
systemctl start enhanced-health-check.service
sleep 3
STATE=$(systemctl show -p Result --value enhanced-health-check.service)
echo "health check Result: $STATE"
if [ "$STATE" = "success" ]; then
    echo "✅ REPAIR OK — health check executed for the first time since 2026-01-28"
    echo "   Backup freshness alarm should have fired for the 5 stale services."
else
    echo "❌ still failing, inspect: systemctl status enhanced-health-check.service"
    exit 1
fi
