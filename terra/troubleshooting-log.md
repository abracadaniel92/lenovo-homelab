# Troubleshooting Log: Terra (offsite backup box)

Changes, incidents and fixes on the Terra. Newest first. Same format as the
lemongrab log at [`docs/reference/troubleshooting-log.md`](../docs/reference/troubleshooting-log.md);
the Pi has its own at [`pihole/troubleshooting-log.md`](../pihole/troubleshooting-log.md).

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
