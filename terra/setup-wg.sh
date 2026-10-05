#!/bin/bash
# Terra stage 2: bring up WireGuard to lemongrab. Run after setup-base.sh and
# after the Terra's public key is added as a peer on lemongrab:
#   sudo bash terra/setup-wg.sh <DDNS name of home>
# The name stays out of this public repo; it's only written to /etc.
set -euo pipefail
cd "$(dirname "$0")"
endpoint=${1:?usage: setup-wg.sh <home IP or DDNS name>}
[ -f /etc/wireguard/terra.key ] || { echo "run setup-base.sh first" >&2; exit 1; }

sed "s/ENDPOINT/$endpoint/" wg0.conf > /etc/wireguard/wg0.conf
chmod 600 /etc/wireguard/wg0.conf
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# wg-quick resolves a DNS name once at start. The home IP is dynamic, so
# re-resolve every 5 min or the Terra keeps dialing a stale address.
peer=$(awk '/^PublicKey/ {print $3}' wg0.conf)
echo "*/5 * * * * root /usr/bin/wg set wg0 peer $peer endpoint $endpoint:51820 2>/dev/null" \
    > /etc/cron.d/terra-wg-reresolve
chmod 0644 /etc/cron.d/terra-wg-reresolve

sleep 3
if ping -c 3 -W 3 10.8.0.1 >/dev/null; then
    echo "OK: lemongrab answers on 10.8.0.1"
else
    echo "FAIL: no reply from 10.8.0.1. Check the peer on lemongrab, or work may block UDP 51820."
    wg show wg0
    exit 1
fi
