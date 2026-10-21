# Troubleshooting Log: Terra (offsite backup box)

Changes, incidents and fixes on the Terra. Newest first. Same format as the
lemongrab log at [`docs/reference/troubleshooting-log.md`](../docs/reference/troubleshooting-log.md);
the Pi has its own at [`pihole/troubleshooting-log.md`](../pihole/troubleshooting-log.md).

## 2026-10-21: watchdog network alerts need two failed runs in a row

**Symptom:** short WireGuard/site dips pushed alerts (10-20 02:27 wg, 05:27
site; the `site` stamp in `/run/terra-watchdog` is dated 10-20 05:27), often
enough to train the owner to ignore pushes.

**Cause: not found.** Nothing in lemongrab's cron or timers (repo) runs near
those times, so "lemongrab's daily restarts" in the entry below was a guess.
Likely a home public IP change (WireGuard waits for the router's No-IP update
and the 5-min `terra-wg-reresolve` cron). Not confirmed: lemongrab refuses SSH
on 10.8.0.1, so its journal wasn't checked from here.

**Change:** `terra/watchdog.sh`: the first failed network check only touches
`$STATE/net-strike`; the wg/site/home push fires if the next run (10 min
later) fails too; a passing run clears it. Backup-staleness alert unchanged.
Installed live: `sudo install -m 0755 terra/watchdog.sh /usr/local/bin/terra-watchdog.sh`
(10:15; the installed copy matched the old repo version before).

**Verification:** `bash terra/test-watchdog.sh` PASS (new case: first
failure doesn't push, second does). Live run 10:24:18: `Result=success`,
exit 0, no `net-strike` left, `ping 10.8.0.1` up.

**Reverse if:** a real outage gets noticed late. Then drop the strike block
(alerts go back to the first failed run).

## 2026-10-21: second unplug test: udev APM rule and BindsTo both verified

**Goal:** test the two fixes from the entry below with a real cable pull
(power cut to the enclosure), not a simulated `udevadm trigger`.

**Test (on the Terra):**
- 09:24:36 `sync && umount /mnt/offsite`: `restic-rest-server` went
  **inactive** at once (on the first test it kept running). `BindsTo=` works.
- Cable pulled about 09:24:40 (`sdb` gone), replugged 09:26:48.
- Before anything touched the drive: `hdparm -B` read **APM_level = 254**, so
  the udev rule worked after a cold power-up (it came back as 128 on the first test).
  rest-server was still **inactive**, so it did not start on its own.
- `mount /mnt/offsite && systemctl start restic-rest-server`: ext4 rw, active,
  listening on `10.8.0.4:8000` by 09:27:18.

**Outcome:** both permanent fixes are proven. The I/O watch for the parking
pattern stopped when the drive went away; restart it to continue that.

**Still open:** why it parks ~5/h at APM 254; noisy wg/site alerts; confirm
the 2026-10-22 04:05 run.

## 2026-10-21: APM udev rule and rest-server BindsTo applied

**Goal:** permanent fixes for the two problems the unplug test (entry below) found.

**EPC ruled out:** `openSeaChest_PowerControl --showEPCSettings` says "not
supported on this device" (through the enclosure it reports as "Portable USB
3.0"; features list APM only). So EPC isn't why it parks at APM 254.

**Change (live on the Terra, copied from the repo):**
- `terra/99-offsite-apm.rules` → `/etc/udev/rules.d/`: on `add` of the disk
  with `ID_SERIAL_SHORT=56HRP1HST`, run `hdparm -B 254`.
- `BindsTo=mnt-offsite.mount` appended to
  `/etc/systemd/system/restic-rest-server.service.d/override.conf`,
  `daemon-reload`. rest-server now stops when the drive goes, and does not
  start by itself when it comes back (`mount /mnt/offsite && systemctl start
  restic-rest-server`; a reboot also does it).
- `terra/setup-offsite.sh` installs both.

**Verification:** `hdparm -B 128` (as after a power-up), then `udevadm trigger
--action=add --sysname-match=sdb`: APM back to **254**. `systemctl show
restic-rest-server`: `BindsTo=mnt-offsite.mount`, active, port 8000 listening.

**Still open:** why it parks ~5/h at APM 254 (watching disk I/O for the
watchdog's 10-min and smartd's 30-min pattern); `BindsTo=` not yet tested by an actual unplug.

## 2026-10-21: unplug test passed on both sides; APM lost on replug

**Goal:** README "Verify": unplug the drive, both sides must alert.
lemongrab's half is in its log (2026-10-21): restic exit 10, ntfy push
arrived, and the Mattermost alert was found dead (Cloudflare 403) and fixed.

**Before the test (read-only):** snapshots `77c31ffd` (10-20 04:11) and
`c64ea872` (10-21 04:06), 6 + 5 new packs (85 + 66 MB), repo 128 GB.
SMART clean, but `Load_Cycle_Count` **263** (28 on 10-19) and +2 in 3 min
idle with `APM_level = 254`: the drive parks anyway (~5/h). Suspect
Toshiba EPC idle timers, which APM does not control.

**Test (on the Terra):**
- 09:00:28 `sync && umount /mnt/offsite` (after clearing the watchdog's
  `backup` stamp), then cable pulled.
- 09:01 watchdog run: pushed only "WireGuard to lemongrab down". The office
  Wi-Fi was dropping packets then (WireGuard ping and DNS failing on and off,
  signal 73), so the backup push most likely failed to send. No stamp, so it retried.
- **09:11:56 backup push sent** ("No new lemongrab backup on the Terra in
  36 h"). The stamp is only written after ntfy accepts it. Terra half passed;
  this closes the item lemongrab's entry left open.
- Replugged, `mount /mnt/offsite`: ext4 mounted clean, rest-server on 8000.
- Backup re-run by hand on lemongrab after the replug: `restic snapshots`
  shows **5 snapshots** (4 before the test), so backups work again.

**Problems found:**
- **rest-server kept running after `umount`** (up since 10-19).
  `RequiresMountsFor` only stops it when systemd stops the mount, not on a
  manual `umount` or a yanked cable. Harmless here: the bare mountpoint is
  root 0755, so rest-server could not write onto the root disk, and lemongrab
  got "repository does not exist". Fix: `BindsTo=mnt-offsite.mount`.
- **APM came back as 128 after the replug.** Debian's hdparm udev hook skips
  APM on USB disks (`hdparm_try_apm` returns 1 for `pci-*-usb-*`), so
  `/etc/hdparm.conf` never applies to this drive. The 10-19 "survives reboot"
  result was a warm reboot that kept the enclosure powered; a power cut
  would reset it too. Fix: a udev rule on `ID_SERIAL_SHORT=56HRP1HST` that
  runs `hdparm -B 254`, plus the EPC check above.
- Watchdog alerts from lemongrab's daily restarts (10-20 02:27 wg, 05:27
  site) arrive often enough to train the owner to ignore pushes.

**Still open:** udev APM rule + EPC (openSeaChest `--showEPCSettings`);
`BindsTo=`; noisy wg/site alerts (find the daily restart, or alert only
after 2 failed runs in a row); confirm the 2026-10-22 04:05 run.

## 2026-10-20: first scheduled nightly backup landed

**Goal:** confirm lemongrab's `backup-immich-terra.timer` (04:00) pushed
a snapshot on its own the first night after Part B.

**Check (on the Terra, read-only):** the repo is `restic-rest-server`-only
(0700), so it needs `sudo`: `sudo ls -la --time-style=full-iso
/mnt/offsite/restic/lemongrab/snapshots/` and
`sudo find /mnt/offsite/restic/lemongrab/data -type f -newermt '2026-10-20 00:00' | wc -l`.

**Verification:** 3 snapshot files:
- `254ffab1` 2026-10-17 (seed on lemongrab)
- `b97ab177` 2026-10-19 10:36 (manual run during Part B)
- `77c31ffd` **2026-10-20 04:11:31** (the timer's run)

The run took ~11 min. 6 new pack files since midnight, so incremental as
expected. `journalctl -u restic-rest-server` shows nothing for the night;
normal, since rest-server does not log requests by default.

**Still open:** this proves a snapshot was written, not its integrity. Run
`restic snapshots` / `restic check` from lemongrab (the repo password lives
there).

## 2026-10-19: APM 254 survives reboot through the USB enclosure

**Goal:** confirm the head-parking fix (same as lemongrab, log 2026-10-17)
persists across a reboot; the reboot test below did not check it.

**Verification (after the reboot):**
- `sudo hdparm -B /dev/sdb`: `APM_level = 254`, so `/etc/hdparm.conf` is
  applied at boot through the Verbatim enclosure. No udev rule needed.
- `Load_Cycle_Count` **28** (baseline 14 in the entry below). Expected some
  growth from the setup work and the reboot (power-off retract + spin-up),
  so this is not yet a sign of parking.

**Still open:** recheck `Load_Cycle_Count` after a week of normal running and
after the first full backup. Steady growth of ~1 per reboot is fine; dozens
per day would mean APM is being lost at runtime.

## 2026-10-19: reboot test with the drive passed; lemongrab reaches the repo

**Goal:** close the "reboot test" and "curl gives 200" open items from the
entry below.

**Test:** owner rebooted the Terra. Checked about 1 min after boot.

**Verification:**
- `findmnt /mnt/offsite`: `/dev/sdb1` ext4 `rw,noatime`, mounted by fstab.
- `restic-rest-server`, `wg-quick@wg0`, `terra-watchdog.timer` all active.
- `ss -tlnp`: listening on `10.8.0.4:8000` only.
- From lemongrab: `curl -u lemongrab http://10.8.0.4:8000/lemongrab/config`
  gives **200**.

**Problem hit:** the first curl got **401**. Not the server:
`sudo htpasswd -v /etc/restic-rest-server/users.htpasswd lemongrab` said the
Vaultwarden password is correct, and the same curl with `-u lemongrab` (curl
prompts for the password) got 200. The password inline on the command line
was mangled. Lesson: in a 401, check the password with `htpasswd -v` first,
then let curl prompt instead of quoting it inline.

**Still open:** Part B on lemongrab; `claude logout`.

## 2026-10-19: offsite drive mounted, rest-server and watchdog running

**Goal:** README Part A steps 2, 4, 6 with the drive seeded on lemongrab
(lemongrab log 2026-10-17).

**Change (live on the Terra), via `sudo bash terra/setup-offsite.sh`:**
- Toshiba MQ04ABD200 2 TB in the Verbatim USB enclosure, `sdb1` ext4 label
  `offsite`, UUID `0bf3f4b3-60ac-472e-a054-fc45a39629a8`. fstab by UUID with
  `nofail,noatime,x-systemd.device-timeout=30s`, mounted at `/mnt/offsite`.
  Nothing formatted; only `chown -R restic-rest-server` on `restic/`.
- `hdparm -B 254` accepted through the enclosure (`APM_level = 254`); block
  appended to `/etc/hdparm.conf`.
- `restic-rest-server` 0.13.0 (trixie package): `LISTEN = 10.8.0.4:8000`,
  `--append-only --private-repos`, htpasswd user `lemongrab` (bcrypt). Drop-in
  `override.conf`: `Wants/After=wg-quick@wg0`, `RequiresMountsFor=/mnt/offsite`.
  The password went to the owner (Vaultwarden); the temp file on the Terra was
  deleted.
- `terra-watchdog.timer` (5 min after boot, every 10 min). Topic URL in
  `/etc/terra-watchdog/ntfy_topic_url`: lemongrab's ntfy.sh topic.

**SMART baseline (2026-10-19):** PASSED. Power_On_Hours 3, Load_Cycle_Count
14, Start_Stop_Count 8, Temperature 33 °C (min/max 21/43), Reallocated,
Pending, Offline_Uncorrectable and UDMA_CRC all 0. Recheck Load_Cycle_Count
and the temperature after the first full backup and after a week.

**Problem hit:** the topic prompt got a bare name (`goce-pi-alerts`) instead
of a URL, so curl could not post and alerts would have failed silently. Fixed
by writing the full `https://ntfy.sh/...` URL. Lesson: the file must hold a
full URL.

**Verification:**
- `ss -tlnp`: `restic-rest-ser` on `10.8.0.4:8000` only.
- `systemctl start terra-watchdog.service`: phone got "No new lemongrab
  backup on the Terra in 36 h" (expected, the seed snapshot is from 2026-10-17;
  it repeats every 6 h until Part B lands a snapshot).
- `bash terra/test-watchdog.sh`: PASS (4/4).
- `df -h /mnt/offsite`: 1.8T, 127G used.

**Still open:** reboot test (drive mounts, rest-server back on 10.8.0.4:8000);
from lemongrab `curl .../lemongrab/config` gives 200; Part B on lemongrab;
`claude logout`.

## 2026-10-05: BIOS "restore on AC power loss" set to On

**Change:** set in the BIOS by the owner, at the box. It boots by itself
after an office power cut.

**Still open:** drive, rest-server and watchdog (README Part A steps 2, 4, 6).

## 2026-10-05: reboot test passed, comes back unattended

**Goal:** close the "reboot test" open item from the base setup entry below.

**Test:** rebooted at 09:53, booted 09:55. Nobody logged in at the box.

**Verification (after boot, over SSH from 10.8.0.1, i.e. through the tunnel):**
- `wg-quick@wg0`, `nftables`, `ssh`, `unattended-upgrades` all active.
- `sleep.target` / `suspend.target` still masked.
- `ping 10.8.0.1`: 0% loss, about 13 ms.
- Wi-Fi `Intertec -Employees` joined at boot without a login (system-wide
  NetworkManager profile, no per-user permissions).

**Notes for a move to another office/network:** see README "Moving to
another network". Short version: the tunnel is outbound to the DDNS name,
so the local IP doesn't matter, but the new Wi-Fi must be saved first.

**Still open:** BIOS "restore on AC power loss" (can't be checked from the
OS); drive, rest-server and watchdog (README Part A steps 2, 4, 6).

## 2026-10-05: base setup and WireGuard to lemongrab (no data drive yet)

**Goal:** make the Terra (hostname `cricket`, kept) reachable remotely before
the 1 TB drive arrives. README Part A steps 1, 3, 5. No rest-server yet.

**Change (live on the Terra):**
- `terra/setup-base.sh`: full-upgrade; installed openssh-server,
  wireguard-tools, nftables, unattended-upgrades, smartmontools, tmux;
  key-only SSH (`ssh/10-key-only.conf`); firewall `terra/nftables.conf` (SSH
  and 8000 only on `wg0`); masked sleep/suspend targets (GNOME suspended after
  15 min idle, which would make the box unreachable); WireGuard key pair in
  `/etc/wireguard/terra.key` (public `vFiy9IqrhAV+jIkbApPKh5uP5vYXK9gHOTKZmxJu+hs=`).
- `~/.ssh/authorized_keys` for `goce`: `goce@lemongrab` and the phone's
  Termius key (`phone-termius-2026-10-05`; an older phone key was removed).
  Phone access: Termius host `10.8.0.4:22` with lemongrab as jump host.
- `terra/setup-wg.sh <DDNS name>`: `/etc/wireguard/wg0.conf` from
  `terra/wg0.conf` (address `10.8.0.4/32`, `AllowedIPs = 10.8.0.1/32`,
  keepalive 25), `wg-quick@wg0` enabled, and
  `/etc/cron.d/terra-wg-reresolve` re-resolving the endpoint every 5 min.

**On lemongrab:** the Terra was added as a peer, `AllowedIPs = 10.8.0.4/32`.

**Problems hit:**
- The first try dialed a raw home IP read off another client's config. The
  home IP had changed (the No-IP name resolved to a different address). Fix:
  dial the No-IP hostname (kept current by the home router), never an IP.
  wg-quick resolves the name only at start, hence the cron.
- lemongrab's public key copied from a screenshot had I/l swapped twice.
  Copy keys as text.

**Verification:** `setup-wg.sh` printed `OK: lemongrab answers on 10.8.0.1`.
`ping -c 3 10.8.0.1` from the Terra: 0% loss, about 27 ms.
`ssh goce@10.8.0.4` from lemongrab logs in.

**Still open:** reboot test (comes back unattended?); BIOS "restore on AC
power loss"; drive, rest-server and watchdog (README Part A steps 2, 4, 6).
