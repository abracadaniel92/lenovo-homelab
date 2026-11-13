#!/bin/bash
# cache-outlook-ics.sh: download the Outlook ICS feed once a day for Cal.com.
#
# Why: Cal re-downloads every ICS feed on every booking-page load. During the
# 2026-11-13 Microsoft slowdown the 480 KB Outlook feed took ~100 s, so the
# booking page took 10-106 s to show free slots. Cal now reads this local copy,
# served by the `ics-cache` busybox container on the private calcom-net network
# (docker/calcom/docker-compose.yml), and never waits on Microsoft.
#
# Cron (user goce): 0 6 * * * /opt/homelab/scripts/cache-outlook-ics.sh 2>&1 | logger -t cache-outlook-ics
# Staleness alert: scripts/health.d/85-ics-cache.sh
#
# ponytail: once a day is enough because the owner's Outlook meetings are set
# weeks ahead. Ceiling: an Outlook event added today is not blocked in Cal until
# tomorrow 06:00. Upgrade path: run the cron more often.

set -euo pipefail

URL_FILE=/home/docker-projects/calcom/outlook-ics-url   # mode 600, the secret feed URL
OUT=/home/docker-projects/calcom/ics-cache/outlook.ics

url=$(cat "$URL_FILE")
tmp=$(mktemp "$OUT.XXXXXX")
trap 'rm -f "$tmp"' EXIT

# Generous timeout: Microsoft has served this file at ~100 s on a bad day.
curl -fsS -m 300 --retry 3 --retry-delay 30 -o "$tmp" "$url"

# Only replace the good copy with something that looks like a whole calendar,
# so a failed or truncated download keeps yesterday's busy times.
if ! grep -q '^BEGIN:VCALENDAR' "$tmp" || ! grep -q '^END:VCALENDAR' "$tmp"; then
    echo "cache-outlook-ics: download is not a complete calendar, keeping old copy" >&2
    exit 1
fi

chmod 644 "$tmp"   # busybox httpd runs as a non-owner user
mv "$tmp" "$OUT"
