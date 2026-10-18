# Troubleshooting Log: Pi (pihole)

Changes, incidents and fixes on the Raspberry Pi 4 (Pi-hole, Unbound, secondary
Uptime Kuma). Newest first. Same format as the lemongrab log at
[`docs/reference/troubleshooting-log.md`](../docs/reference/troubleshooting-log.md);
the Terra has its own at [`terra/troubleshooting-log.md`](../terra/troubleshooting-log.md).
Pi entries from before 2026-10-03 are in the lemongrab log.

## [2026-10-18] Weekly review: open items

First per-machine weekly review on the Pi. Items checked against live state.

**Closed:**
- Firmware/OS updates and reboot (from log 2026-10-17): rebooted 2026-10-17
  18:37; `swapon --show` lists zram0 only; `/var/swap` is gone.
- Uptime Kuma off lemongrab's compose (from log 2026-10-03): runs
  `louislam/uptime-kuma:2` with data in `pihole/docker/uptime-kuma/data`.
- `sshd` password auth (from lemongrab log 2026-10-08 item 7, never logged
  here): disabled by the owner; `sshd -T` shows `passwordauthentication no`.

**Drift:** pihole, unbound, uptime-kuma up; upstream `127.0.0.1#5335`;
`pi-backup.timer` last ran 2026-10-18 02:32; Unbound mounts `unbound.conf`
from this checkout. 5 apt packages upgradable.

**Carried over:** none.

## [2026-10-17] Pi-hole was using Google DNS, not Unbound; Pi-hole and Kuma upgraded; zram-only swap

**Symptom:** `docker exec pihole pihole-FTL --config dns.upstreams` showed
`[ 8.8.8.8, 8.8.4.4 ]`. Every LAN lookup went to Google; Unbound was running
but unused. Cause: the compose file set `PIHOLE_DNS_: '127.0.0.1#5335'`, a v5
variable that Pi-hole v6 ignores. The same applies to its `WEBPASSWORD` and
`FTLCONF_LOCAL_IPV4` placeholders, so they never reset anything either; v6
keeps all settings in `pihole.toml` on the `pihole_config` volume.

**Changes:**
- `pihole/docker/pihole/docker-compose.yml`: removed the three v5 variables,
  added a comment on where v6 settings live. Recreated from this (current) path:
  `docker compose pull && docker compose up -d`. Pi-hole is now Core v6.5,
  Web v6.6.1, FTL v6.8. Password, 3 adlists and ~897k gravity domains carried
  over (same `pihole` project, same named volumes).
- `pihole/docker/unbound/unbound.conf`: `auto-trust-anchor-file:
  "/var/unbound/root.key"` (DNSSEC validation; the file ships with the
  klutchell image) and `cache-min-ttl` 3600 → 300, so moved services are not
  pinned to stale IPs for an hour. Checked with `unbound-checkconf`, then
  `docker compose restart unbound`.
- Upstream switched: `docker exec pihole pihole-FTL --config dns.upstreams
  '["127.0.0.1#5335"]'`. Revert: same command with `'["8.8.8.8","8.8.4.4"]'`.
- Uptime Kuma 1.23.17 → 2.5.6, moved to its own compose at
  `pihole/docker/uptime-kuma/` (resolves the open item from 2026-10-03). Data
  moved from `docker/uptime-kuma/data/` to `pihole/docker/uptime-kuma/data/`.
  v1 data saved first as `~/kuma-v1-data-20261017.tar.zst`. The v2 aggregate
  table migration took ~7 min for 10 monitors (3-day history); the UI shows only
  a progress page until it finishes ("cannot get settings" meanwhile).
  `pihole/backup/pi-backup.sh` `KUMA=` path updated and reinstalled.
- Swap: `/etc/rpi/swap.conf.d/90-zram-only.conf` sets `Mechanism=zram`. The
  default `zram+file` wrote idle zram pages to the 2 GB `/var/swap` on the SD
  card (`rpi-zram-writeback.timer`). Takes effect at next boot, which also
  removes `/var/swap`.
- ModemManager left running and CUPS kept on purpose (printer in daily use).

**Verification:**
- `docker exec pihole dig @127.0.0.1 -p 5335 cloudflare.com` has the `ad` flag;
  `dnssec-failed.org` returns SERVFAIL.
- 12 uncached domains through Pi-hole resolved in 55–260 ms, 0 failures; the
  Pi-hole log shows `forwarded ... to 127.0.0.1#5335`.
- Kuma: 10/10 monitors up after migration; `keepDataPeriodDays` still 3.
- `pi-20261017-183354.tar.zst` (49 MB) uploaded with the new Kuma path.

**Lessons:**
- After a Pi-hole major upgrade, check the effective config
  (`pihole-FTL --config`), not the compose env; ignored variables fail silently.
- Do not use `docker/uptime-kuma/` on the Pi: it is lemongrab's mirrored compose.

**Pending (owner):** firmware and OS updates, then reboot:
`sudo rpi-eeprom-update -a && sudo apt update && sudo apt full-upgrade -y && sudo reboot`.
After the reboot, check `swapon --show` (zram0 only) and that `/var/swap` is gone.

**Status:** ✅ Done, except the pending reboot.

## [2026-10-17] Moved to a 128 GB SD card, cut SD writes, nightly backup to lemongrab

**SD card:** cloned the 29 GB boot card onto a 128 GB card with `rpi-clone`
(`~/clone-sd.sh`) and swapped. Root grew to 114 GB, same PARTUUID
(`7e08cf8b`), so `cmdline.txt` and fstab needed no change. The old 29 GB card is
kept as a bootable fallback. The new card reports a generic ID (manfid `0x9f`,
`SD128`) and is slow (~28 MB/s read, ~10 MB/s write) but has been filled to
~110 GB before, so its capacity is real.

**SD wear (`~/sd-wear.sh`):**
- Pi-hole `database.DBinterval` 60 → 1800 s (set with `pihole-FTL --config`,
  stored in `pihole.toml` on the volume). `maxDBdays` was already 7.
- `/etc/docker/daemon.json`: default `json-file` logs capped at 10m × 3. Only
  applies to new containers; pihole and unbound were not recreated (their logs
  are a few hundred KB).
- Uptime Kuma monitor history set to 3 days in its UI.
- Already in place: `noatime`, zram swap, `/tmp` on tmpfs, journald 50M /
  `SyncIntervalSec=15m`, `fstrim.timer`.
- Note: Docker's `data-root` is `/mnt/ssd/docker/docker`, but no SSD is mounted
  on the Pi; it is a plain directory on the SD card.

**Backup:** new `/usr/local/sbin/pi-backup.sh`, run by `pi-backup.service` /
`pi-backup.timer` (02:30 + up to 10 min). Builds a ~50 MB
`pi-YYYYMMDD-HHMMSS.tar.zst` in `/tmp` and rsyncs it to lemongrab port 223 with
the root key `/root/.ssh/pi-backup`. lemongrab's receiver (rrsync `-wo`, 14-day
prune, B2 offsite, 36 h freshness alert) is logged in the lemongrab log, same
date. Contents: `/etc`, `/var/spool/cron`, both Pi-hole volumes (`gravity.db`
via SQLite online backup; query DB `pihole-FTL.db` excluded), `kuma.db` (online
backup), `~/Desktop`, `~/.ssh`, `~/.claude`, dotfiles, `dpkg --get-selections`
and `docker inspect` of all containers. Includes credentials by choice.

**Repo:** live files mirrored into `pihole/backup/` (`pi-backup.sh`,
`pi-backup.service`, `pi-backup.timer`). Deploy changes with
`sudo install -m 0755 pihole/backup/pi-backup.sh /usr/local/sbin/` and copy the
units to `/etc/systemd/system/` + `systemctl daemon-reload`.

**Verification:** first run (`sudo systemctl start pi-backup.service`) uploaded
`pi-20261017-180317.tar.zst` (48 MB); goce confirmed it in
`/mnt/ssd_1tb/backups/pi` on lemongrab. `systemctl list-timers pi-backup.timer`
shows the next run. The Pi key is write-only, so arrivals can only be checked
on lemongrab (or via its Mattermost freshness alert).

**Lessons:**
- The repo's `pihole/docker/pihole/docker-compose.yml` still has placeholder
  `WEBPASSWORD`/`FTLCONF_LOCAL_IPV4`. Do not recreate Pi-hole from it; the live
  container's settings are in each backup's `meta/docker-inspect.json`.
- The 2026-10-03 entry's "no custom systemd units, timers or cron jobs" is no
  longer true: `pi-backup.service`/`.timer` now exist.

**Status:** ✅ Running on the 128 GB card; nightly backup enabled.

## [2026-10-13] Removed unused Cloudflare WARP client

**Symptom:** low free RAM. `warp-svc` (~530 MB RSS) and `warp-taskbar`
(~220 MB) were the largest processes on the Pi, together about 20% of its 4 GB.
WARP was installed around 2026-01-10 but never registered (`warp-cli status`:
`Registration Missing`), so it tunnelled nothing. It started at every boot
anyway, with the tray app autostarting in the desktop session.

**Change (live):**
```bash
pkill -u goce warp-taskbar
sudo systemctl disable --now warp-svc
sudo apt-get purge -y cloudflare-warp
sudo apt-get autoremove -y
sudo rm -f /etc/apt/sources.list.d/cloudflare-client.list \
  /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
sudo rm -rf /var/lib/cloudflare-warp
```
`autoremove` also took WARP's tray/TPM libraries (libwebkit2gtk, libtss2-*,
libayatana-appindicator3, etc.) and `chromium-sandbox`, which had only been held
by WARP. Chromium is installed and recommends that package, so it was put back:
`sudo apt install chromium-sandbox`.

**Not affected:** nothing on the Pi used WARP. Remote access is SSH on :222;
Pi-hole and Uptime Kuma are LAN-only.

**Verification:** no `warp` processes, `warp-svc.service` not found, no WARP
autostart entry or apt source left. Memory used went from 1.5 GiB to ~900 MiB;
available went from 2.2 GiB to 2.8 GiB. No OOM kills in the 16 days before.

## [2026-10-03] Folder move left Unbound pointing at a deleted config; Pi folder filled in

**Symptom:** none visible yet, caught before it bit. Commit e940ab4 moved the Pi
stacks from `docker/{pihole,unbound}/` to `pihole/docker/{pihole,unbound}/`. The
Pi's checkout was on `develop`; `git checkout main` deleted
`docker/unbound/unbound.conf`. The running `unbound` container bind-mounts that
file (`./unbound.conf:/etc/unbound/unbound.conf:ro`), so it kept working on the
open inode, but the next restart or reboot would have had Docker create an empty
directory at the old path, Unbound would fail to start, and Pi-hole (which
forwards to `127.0.0.1:5335`) would stop resolving for the whole network.

**Change (live):** confirmed the moved `unbound.conf` and compose files differ
from the old ones only in whitespace (`git diff -M -w e940ab4^ e940ab4`), then
recreated Unbound from the new path:
```bash
cd ~/Desktop/Cursor/Pi-version-control/Pi-version-control/pihole/docker/unbound
docker compose up -d
```
Pi-hole was not touched: it uses named volumes (`pihole_pihole_config`,
`pihole_dnsmasq_config`) and the compose dir basename is unchanged, so the
project name and volumes stay the same.

**Change (repo, branch `feature/pi-folder-cleanup`):**
- Added `pihole/ssh/01-nopass.conf`, a mirror of the live
  `/etc/ssh/sshd_config.d/01-nopass.conf` (`PasswordAuthentication no`). SSH
  port 222 is set in `/etc/ssh/sshd_config`.
- `pihole/README.md`: added a "What runs on the Pi" table (component, repo path,
  live location), a warning about the Unbound bind mount, and the live Pi-hole
  versions (Core v6.4.3, Web v6.6, FTL v6.7.1).
- Started this log.

**Checked, no change needed:** live `/etc/fail2ban/jail.d/pi.local` is identical
to `pihole/fail2ban/pi.local`. No custom systemd units, timers or cron jobs on
the Pi. No WireGuard on the Pi.

**Verification:** `docker inspect unbound` shows status `running`, 0 restarts,
mount source `.../pihole/docker/unbound/unbound.conf`. A query straight to
Unbound returned addresses: `docker exec pihole dig @127.0.0.1 -p 5335 example.com +short`.
Normal resolution on the Pi works (`getent hosts example.com`).

**Lessons:**
- On the Pi, Unbound reads its config straight from the repo checkout. Any branch switch, pull
  or move that touches `pihole/docker/unbound/` needs a `docker compose up -d`
  there afterwards. Check with
  `docker inspect unbound --format '{{range .Mounts}}{{.Source}}{{end}}'`.
- `dig` is not installed on the Pi host; use the copy inside the Pi-hole
  container (`docker exec pihole dig ...`).

**Open:**
- The Pi's Uptime Kuma still runs from `docker/uptime-kuma/` (compose shared
  with lemongrab, data in `docker/uptime-kuma/data/`, gitignored). It runs
  the `louislam/uptime-kuma:latest` image, while the compose now pins `:2`, so
  recreating it is a major upgrade. Left as is; decide whether to move it under
  `pihole/` and upgrade together.

**Status:** ✅ Unbound running from the new path; repo changes awaiting commit.
