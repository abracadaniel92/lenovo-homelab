#!/bin/bash
# Terra: install Uptime Kuma (Docker, host network, UI on 127.0.0.1:3001).
# Run on the Terra from the repo root:  sudo bash terra/setup-uptime-kuma.sh
# Safe to re-run (also pulls a newer :2 image). Touches nothing on /mnt/offsite.
set -euo pipefail
cd "$(dirname "$0")"
DIR=/opt/uptime-kuma

apt-get update
apt-get install -y docker.io docker-compose

# Docker must not touch the firewall: nftables.conf does "flush ruleset", and
# the Terra only needs host networking. No default bridge, small logs (SSD).
if [ ! -f /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'JSON'
{
  "iptables": false,
  "bridge": "none",
  "log-driver": "local",
  "log-opts": { "max-size": "10m" }
}
JSON
    systemctl restart docker
fi
systemctl enable --now docker

install -d -m 0750 "$DIR/data"
install -m 0644 uptime-kuma/docker-compose.yml "$DIR/docker-compose.yml"

if docker compose version >/dev/null 2>&1; then DC="docker compose"; else DC=docker-compose; fi
$DC -f "$DIR/docker-compose.yml" pull
$DC -f "$DIR/docker-compose.yml" up -d

echo "== waiting for Uptime Kuma on 127.0.0.1:3001"
for _ in $(seq 1 60); do
    curl -fsS -o /dev/null http://127.0.0.1:3001 && break
    sleep 2
done
curl -fsS -o /dev/null -w 'HTTP %{http_code}\n' http://127.0.0.1:3001
ss -tlnp | grep ':3001 ' || { echo "nothing listening on 3001" >&2; exit 1; }
ss -tlnp | grep ':3001 ' | grep -qv '127.0.0.1:3001' \
    && { echo "WARN: 3001 is bound beyond 127.0.0.1" >&2; exit 1; }
nft list table inet filter >/dev/null && echo "nftables filter table intact"
echo "OK. From your laptop: ssh -J goce@<lemongrab> -L 3011:localhost:3001 goce@10.8.0.4"
echo "then open http://localhost:3011 and create the admin user."
