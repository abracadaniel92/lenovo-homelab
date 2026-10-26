# Troubleshooting Log: Terra (offsite backup box)

Changes, incidents and fixes on the Terra. Newest first. Same format as the
lemongrab log at [`docs/reference/troubleshooting-log.md`](../docs/reference/troubleshooting-log.md);
the Pi has its own at [`pihole/troubleshooting-log.md`](../pihole/troubleshooting-log.md).

## 2026-10-26: backups fine; Load_Cycle_Count ~152/day over 4 days (at the line)

**Check (read-only, Terra, no sudo):** `terra-watchdog` runs every 10 min,
last at 10:27:46 `Result=success`. `/run/terra-watchdog` has no `backup`
stamp, so a snapshot landed within the last 36 h. Its only stamps are the old
`site` (10-20) and `wg` (10-21). The dir mtime of 01:37 is a single
`net-strike` that was set and then cleared: the nightly line drop, so no push.
rest-server is listening on `10.8.0.4:8000`; `/mnt/offsite` 129 G of 1.8 T.
Snapshot times were not listed: the repo dirs need root.

**SMART** (read through udisks2 D-Bus `SmartGetAttributes`, no root needed,
updated 10:29:40): `Load_Cycle_Count` **1061** (448 at 10-22 ~11:00, so +613
in ~96.5 h, **~152/day**, ~6.3/h). Temperature 33 °C; Reallocated,
Reallocated_Event, Current_Pending, Offline_Uncorrectable and Load_Retry all
0. Power-on 172 h, heads loaded 29 h.

**Open:** the recheck promised in the entry below. The rate holds steady at
~150-160/day, right on the udisks2 reverse line (~56k/yr, ~11 years to
600k). The rate is steady and the line is barely crossed, so nothing was
changed. The owner decides whether to revisit (see the reverse conditions
in the udisks2 entry).

## 2026-10-22: nightly backup landed; Load_Cycle_Count +161 in 24 h

**Check (read-only, Terra):** snapshot file in `snapshots/` written 04:06:47
(third nightly in a row: 10-20 04:11, 10-21 04:06); 5 packs, ~0.06 GiB in
`data/` since 10-21 20:00. Watchdog silent overnight. `/mnt/offsite` 128 G
used of 1.8 T.

**SMART (~11:00):** `Load_Cycle_Count` **448** (287 at 10-21 10:44, so
+161 in ~24 h, ~6.7/h). Temperature 33 °C (min/max 21/43); Reallocated,
Reallocated_Event and Current_Pending all 0.

**Open:** +161/day is just over the ~150/day reverse line in the udisks2
entry below. One day isn't a trend: recheck about 11:00 on 10-23; if still
over 150/day, revisit that decision.

## 2026-10-21: cause of the wg/site dips: home internet line, not lemongrab

**Closes** the open cause from "watchdog network alerts need two failed runs
in a row" (below). Found from lemongrab (owner's lemongrab session).

**Findings:**
- 10-20 05:25: every external `*.gmojsoski.com` check timed out at once while
  the local Caddy check stayed up; the Cloudflare tunnel lost all 4
  connections at 05:26:50 and was back at 05:27:04 (~2 min in total).
- lemongrab's journal for the window: no link drop, NIC errors or WireGuard
  messages; the 05:30 health check ran clean. The server kept its LAN link;
  the path out to the internet went down. WireGuard dipped too because the
  Terra reaches lemongrab over the same line via the DDNS name.
- A nightly drop at about **02:20** (10-21 3 min, caught by Kuma; 10-20 14 s;
  09-24): a scheduled router restart or a provider-forced reconnect, likely
  with a new public IP. The 05:25 one was a one-off.

**Decision (owner): ignore.** Drops are 2-3 min, far from the 04:05 backup,
and recover on their own. The two-strike watchdog already keeps them quiet:
a dip shorter than the 10-min interval can fail only one run.

**Not checked:** the router's log (WAN/PPPoE reconnect, DDNS IP change).

**Reverse if:** a drop lasts over 10 min, or one starts overlapping the
04:00-04:15 backup window: then move or disable the router's restart.

## 2026-10-21: smartd warnings push to ntfy; Terra gets its own topic and priorities

**Symptom:** smartd mailed root, but the Terra has no MTA (`10mail` hook:
"does not have /usr/bin/mail"), so SMART warnings went nowhere.

**Change (live, Terra):**
- `terra/smartd-ntfy.sh` → `/etc/smartmontools/run.d/05ntfy` (runs before
  `10mail` via smartd-runner): pushes "SMART warning on <sdX>: <type>".
  By-id paths are resolved to the kernel name so the serial never reaches
  the public topic. `setup-offsite.sh` installs it.
- `/etc/terra-watchdog/ntfy_topic_url` now holds a **Terra-only** ntfy.sh
  topic (owner subscribed). lemongrab's topic also carries Uptime Kuma, and a
  test push got lost there. Topic name stays out of the repo.
- `terra/watchdog.sh` (installed 11:21): priorities per alert: `urgent`
  lemongrab offline, `high` no backup in 36 h, `default` site or WireGuard
  alone. The owner sets up the phone's notification sounds per priority.

**Verification:**
- `smartd -q onecheck` with a `-M test` config: push "SMART warning on sdb:
  EmailTest" arrived on the new topic. The first test (old topic) did not
  show up on the phone, though smartd shows `05ntfy` exited cleanly.
- `bash terra/test-watchdog.sh` PASS (now also checks the priority header).
- Live `05ntfy` and `/usr/local/bin/terra-watchdog.sh` match the repo
  (apart from a header comment edited afterwards).

**Reverse if:** the separate topic gets missed; put lemongrab's URL back in
the topic file.

## 2026-10-21: udisks2 SMART polling can't be switched off per drive; ~6 parks/h accepted

**Goal:** stop udisks2's 10-min SMART poll on the offsite drive (entry below)
without masking udisks2.

**Tried (both live on the Terra, both reverted):**
1. `ENV{UDISKS_IGNORE}="1"` for serial `56HRP1HST` in `99-offsite-apm.rules`,
   `udevadm trigger --action=change`: udisks2 set `HintIgnore=true` but still
   polled at 11:05:41. It only hides the drive from desktop tools.
2. `ENV{ID_ATA_FEATURE_SET_SMART}="0"` (+ `_ENABLED`), then `systemctl
   restart udisks2`: `SmartSupported` stayed true and the restart itself
   polled (11:09:39). udisks2 asks the drive itself, not udev.
Reverted: repo rule restored, reinstalled, `change` trigger; live rule ==
repo, SMART properties back to 1.

**Why not mask udisks2:** the Terra boots `graphical.target` (lightdm), and
`fwupd-refresh.timer` is enabled; fwupd uses udisks2 to find the ESP
(`/dev/sda1`).

**Decision (owner): accept ~6 parks/h** (udisks2 ~6/h; smartd now 3 h).
~53k/yr, about 11 years to a ~600k rating; lemongrab's review called 5/h fine.
Last readings: `Load_Cycle_Count` 280 (09:44) → 287 (10:44), before smartd
went to 3 h. Parking watch stopped.

**Reverse if:** `Load_Cycle_Count` grows past ~150/day (check it monthly), or
the Terra goes headless (then mask udisks2 and point fwupd at the ESP).

## 2026-10-21: parking traced to SMART polling; smartd every 3 h

**Symptom:** at APM 254 the offsite drive still parks: `Load_Cycle_Count`
280 → 287 from 09:44 to 10:44, with **zero** block reads or writes the whole
hour (`/sys/block/sdb/stat` flat at 1644/5; minute log + hourly smartctl,
`io-watch.sh` in the session scratchpad).

**Ruled out:** EPC (unsupported, entry below); ext4lazyinit (finished);
atime (mounted `noatime`); the watchdog: after its first run following the mount,
its `find` over `snapshots/` is served from cache (runs at 09:42, 09:53 did
no I/O).

**Cause:** SMART polls are drive accesses that block stats don't count. Each
access after idle loads the heads; they park again soon after.
- **udisks2** refreshes SMART every 10 min (`SmartUpdated` on its D-Bus drive
  object: 10:45:41, then 10:55:41): ~6/h.
- **smartd** on the default 30 min: ~2/h.
That's ~8 accesses/h against 7 parks/h.

**Change (live, Terra):** `/etc/default/smartmontools` gets
`smartd_opts="--interval=10800"` (backup `.bak-20261021`), `systemctl
restart smartmontools`; running as `/usr/sbin/smartd -n --interval=10800`.
`terra/setup-offsite.sh` does the same.

**Found on the way:** smartd alerts go nowhere. It mails root (`-m root`,
`10mail` hook) but the Terra has no `sendmail`/`mail`.

**Not changed:** udisks2. Masking it would break fwupd (firmware updates use
it to find the EFI partition) plus gvfs/thunar/gnome-disk-utility. The targeted
option, `ENV{UDISKS_IGNORE}="1"` for this serial in `99-offsite-apm.rules`, is
untested: it may only hide the drive from the desktop and keep polling it.

**Expected:** ~6/h until udisks2 is dealt with (~53k/yr, fine for a ~600k
rating); under 1/h after.

**Still open:** udisks2 polling (try `UDISKS_IGNORE`, check `SmartUpdated`
stops moving); smartd alerts to ntfy via `-M exec`.

**Reverse if:** a SMART problem should be caught within the hour: drop the
`smartd_opts` line and restart smartmontools.

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
