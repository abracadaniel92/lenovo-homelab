#!/bin/bash
# Daily Pi backup -> lemongrab:/mnt/ssd/backups/pi (then B2 via lemongrab's sync).
# Built in /tmp (RAM) so it adds no SD card writes. Runs as root from pi-backup.timer.
set -euo pipefail

DEST_HOST=192.168.1.97
DEST_PORT=223
DEST_USER=goce
KEY=/root/.ssh/pi-backup
HOME_DIR=/home/goce
PIHOLE=/mnt/ssd/docker/docker/volumes/pihole_pihole_config/_data
KUMA="$HOME_DIR/Desktop/Cursor/Pi-version-control/Pi-version-control/docker/uptime-kuma/data"

STAMP=$(date +%Y%m%d-%H%M%S)
WORK=$(mktemp -d /tmp/pi-backup.XXXXXX)
trap 'rm -rf "$WORK"' EXIT
S="$WORK/pi-$STAMP"
mkdir -p "$S/meta" "$S/sqlite"

# Live SQLite DBs: consistent online copies (reads through the WAL).
sqlite3 "file:$PIHOLE/gravity.db?mode=ro" ".backup '$S/sqlite/gravity.db'"
sqlite3 "file:$KUMA/kuma.db?mode=ro" ".backup '$S/sqlite/kuma.db'"
for db in "$S"/sqlite/*.db; do
    [ "$(sqlite3 "$db" 'PRAGMA integrity_check;')" = ok ] || { echo "integrity check failed: $db" >&2; exit 1; }
done

# Rebuild info: packages, crontabs, how the containers are actually running.
dpkg --get-selections > "$S/meta/dpkg-selections.txt"
crontab -l -u goce > "$S/meta/crontab-goce.txt" 2>/dev/null || true
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' > "$S/meta/docker-ps.txt"
docker inspect $(docker ps -aq) > "$S/meta/docker-inspect.json"

tar -C / --zstd -cf "$WORK/pi-$STAMP.tar.zst" \
    --exclude="${PIHOLE#/}/gravity*.db" --exclude="${PIHOLE#/}/pihole-FTL.db*" \
    --exclude="${PIHOLE#/}/listsCache" \
    --exclude="${KUMA#/}/kuma.db*" \
    --exclude='home/goce/.claude/projects/*/*.jsonl' \
    --exclude='node_modules' \
    etc \
    var/spool/cron \
    mnt/ssd/docker/docker/volumes/pihole_pihole_config \
    mnt/ssd/docker/docker/volumes/pihole_dnsmasq_config \
    home/goce/Desktop \
    home/goce/.ssh \
    home/goce/.claude \
    home/goce/.bashrc home/goce/.profile \
    $(cd / && ls -d home/goce/*.sh 2>/dev/null) \
    -C "$WORK" "pi-$STAMP"

rsync -t --chmod=F600 -e "ssh -i $KEY -p $DEST_PORT -o BatchMode=yes" \
    "$WORK/pi-$STAMP.tar.zst" "$DEST_USER@$DEST_HOST:"

echo "Uploaded pi-$STAMP.tar.zst ($(du -h "$WORK/pi-$STAMP.tar.zst" | cut -f1))"
