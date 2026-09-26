#!/bin/bash
# One-off: install the weekly image-update check (scripts/update-check.sh).
#
#   sudo bash scripts/setup-update-check-timer.sh
#
# Mondays 10:00 it pushes one ntfy notification listing images whose tag has
# a newer build. It never pulls or restarts anything. Replaces the archived
# Watchtower, which auto-updated and would have taken Jellyfin :latest to a
# new major version unannounced. Idempotent: safe to re-run.
set -uo pipefail

[ "$EUID" -eq 0 ] || { echo "❌ Must run as root: sudo bash $0"; exit 1; }

cat > /etc/systemd/system/update-check.service <<'EOF'
[Unit]
Description=Weekly check for newer Docker images (ntfy push, no updates applied)
OnFailure=notify-failure@%n.service
Wants=network-online.target
After=network-online.target docker.service

[Service]
Type=oneshot
# Runs as root like the health check: it shares ntfy-push.sh's /run state dir.
ExecStart=/opt/homelab/scripts/update-check.sh
TimeoutStartSec=30min
EOF
cat > /etc/systemd/system/update-check.timer <<'EOF'
[Unit]
Description=Weekly Docker image update check

[Timer]
OnCalendar=Mon *-*-* 10:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF
systemctl daemon-reload
systemctl enable --now update-check.timer >/dev/null 2>&1 || { echo "❌ could not enable timer"; exit 1; }
echo "✅ update-check.timer enabled, next run:"
systemctl list-timers update-check.timer --no-pager | sed -n 2p
