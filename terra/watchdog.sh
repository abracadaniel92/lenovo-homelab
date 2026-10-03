#!/bin/bash
# Terra watchdog: pushes to the phone when lemongrab is offline, or when its
# backups stop arriving. lemongrab can't report its own power or internet
# outage; the Terra, sitting outside the house, can.
#
# Runs every 10 min from terra-watchdog.timer (see README, Part A step 6).
# Install: sudo install -m 0755 watchdog.sh /usr/local/bin/terra-watchdog.sh
# Topic URL: /etc/terra-watchdog/ntfy_topic_url (0600), the same public ntfy.sh
# topic lemongrab uses. Title only, never details (anyone with the topic name
# can read it).
#
# ponytail: one push per problem per 6 h, stamps in tmpfs. Ceiling: no
# "recovered" message and stamps reset on reboot. Upgrade path: clear the
# stamp and push "back up" when a check passes again.
set -uo pipefail

TOPIC_URL=$(cat "${TOPIC_FILE:-/etc/terra-watchdog/ntfy_topic_url}") || exit 1
SNAP_DIR="${SNAP_DIR:-/mnt/offsite/restic/lemongrab/snapshots}"
SITE="${SITE:-https://gmojsoski.com}"
LEMONGRAB_WG="${LEMONGRAB_WG:-10.8.0.1}"
STATE="${STATE:-/run/terra-watchdog}"
mkdir -p "$STATE"

alert() { # alert <title> <key>
    local stamp="$STATE/$2"
    [ -n "$(find "$stamp" -mmin -360 2>/dev/null)" ] && return
    curl -fsS --max-time 10 -H "Title: terra" -H "Priority: high" \
        -d "$1" "$TOPIC_URL" >/dev/null && touch "$stamp"
}

# Retries ride out a blip, so one dropped packet doesn't wake anyone.
site_ok=1; curl -fsS -o /dev/null --max-time 15 --retry 2 --retry-delay 30 \
    --retry-all-errors "$SITE" || site_ok=0
wg_ok=1; ping -c 3 -W 5 "$LEMONGRAB_WG" >/dev/null || wg_ok=0

if [ $site_ok = 0 ] && [ $wg_ok = 0 ]; then
    alert "lemongrab offline: site and WireGuard both down (home power or internet?)" home
elif [ $site_ok = 0 ]; then
    alert "gmojsoski.com down but lemongrab answers on WireGuard (Caddy/cloudflared?)" site
elif [ $wg_ok = 0 ]; then
    alert "WireGuard to lemongrab down, site is up" wg
fi

# restic writes one small file per snapshot into snapshots/. The Terra can't
# read them (encrypted) but can see when the last one landed. A missing dir
# (drive not mounted) also alerts.
if [ -z "$(find "$SNAP_DIR" -type f -mmin -2160 -print -quit 2>/dev/null)" ]; then
    alert "No new lemongrab backup on the Terra in 36 h" backup
fi
