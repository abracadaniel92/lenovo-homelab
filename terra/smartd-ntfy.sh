#!/bin/sh
# smartd warning -> phone push. smartd mails root, but the Terra has no MTA,
# so its warnings went nowhere (log 2026-10-21). smartd-runner runs this from
# run.d before 10mail.
# Install: sudo install -m 0755 smartd-ntfy.sh /etc/smartmontools/run.d/05ntfy
# Same public ntfy topic as the watchdog: failure type and device name only,
# never the model/serial in SMARTD_DEVICEINFO or the full message.
TOPIC_URL=$(cat "${TOPIC_FILE:-/etc/terra-watchdog/ntfy_topic_url}") || exit 1
# Resolve by-id paths (they carry the serial) to the kernel name, e.g. sdb.
dev=$(basename "$(readlink -f "${SMARTD_DEVICE:-unknown}")")
curl -fsS --max-time 10 --retry 2 -H "Title: terra" -H "Priority: urgent" \
    -d "SMART warning on $dev: ${SMARTD_FAILTYPE:-unknown}. Run smartctl -a." \
    "$TOPIC_URL" >/dev/null
