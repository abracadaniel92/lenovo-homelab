# Terra: offsite backup box at work

**Status (2026-10-17):** base, WireGuard (`10.8.0.4`), firewall, reboot test
and BIOS power-on are done (`troubleshooting-log.md` here). The data drive is
seeded on lemongrab and moves to the Terra on Monday 2026-10-19. Not done yet:
drive mount, rest-server, watchdog, then lemongrab's Part B.

## Start here (Claude on the Terra, 2026-10-19)

The drive is a **Toshiba MQ04ABD200 2 TB in a Verbatim USB enclosure**,
`/dev/disk/by-id/ata-TOSHIBA_MQ04ABD200_56HRP1HST`, one ext4 partition
labelled `offsite`. It already holds the restic repo
`restic/lemongrab/` with one snapshot (`254ffab1`, 133 GiB, `restic check`
clean). **Do not format, `mkfs`, `restic init` or write into it.** You
can't read it anyway: the restic password stays on lemongrab.

Do, in order, and log each in `troubleshooting-log.md` (this folder):
1. Plug in, `lsblk -f`, confirm label `offsite`. `smartctl -H -A` on the
   by-id path, record `Load_Cycle_Count` and temperature.
2. Part A step 2: fstab by UUID with `nofail`, mount `/mnt/offsite`, APM 254
   + `/etc/hdparm.conf`, `chown -R restic-rest-server:restic-rest-server
   /mnt/offsite/restic` (after step 3 below creates that user).
3. Part A step 4 (rest-server), step 6 (watchdog), step 7 (log out).
4. Reboot, confirm the drive mounts and rest-server listens on
   `10.8.0.4:8000` (`ss -tlnp`). From lemongrab:
   `curl -u lemongrab:<pw> http://10.8.0.4:8000/lemongrab/config -o /dev/null -w '%{http_code}'`
   gives 200.
5. Hand the owner the htpasswd password for `lemongrab`. The rest (Part B) is
   done from lemongrab.

Expect one false alarm: the seed snapshot is from 2026-10-17, so the watchdog's
"no new backup in 36 h" push fires as soon as it runs, and every 6 h until
lemongrab's Part B timer lands its first snapshot. That is the alert working,
not a fault.

The Terra, a small PC at the office (see Hardware), holds a second offsite copy of the Immich photo
library. With Backblaze B2 that makes three copies: lemongrab, the Terra, B2.
Work has approved the Terra on their network.

This doc is the brief for whoever sets it up, including Claude Code running
on the Terra. **Part A runs on the Terra. Part B runs on lemongrab.** Don't mix them
up: the Terra must never get access to lemongrab.

## Design

```
lemongrab (10.8.0.1)  --restic over WireGuard-->  Terra (10.8.0.4)
  holds: restic password                            holds: encrypted blobs only
  runs:  nightly systemd timer                      runs:  rest-server --append-only
```

- **One-way trust.** lemongrab pushes to the Terra. The Terra has no SSH key, password
  or token for lemongrab. If the Terra is compromised, the server is not.
- **Encrypted at rest.** restic encrypts everything client-side. The restic
  password lives on lemongrab and in Vaultwarden, never on the Terra. A stolen
  Terra or drive shows only ciphertext.
- **Append-only.** `rest-server --append-only` lets lemongrab add snapshots but
  not delete or overwrite them. Ransomware on lemongrab can't wipe this copy.
- **Outbound only.** The Terra dials home over WireGuard with a keepalive. No port
  is opened on the work network. rest-server listens on the WireGuard IP only.
- **Alert on silence.** A missed backup pushes to the phone via ntfy, same as
  every other homelab failure.

## Facts about lemongrab (verified 2026-09-27)

| Thing | Value |
|---|---|
| WireGuard | `wg-quick@wg0`, server IP `10.8.0.1/24`, UDP `51820` |
| Public endpoint | No-IP DDNS hostname, kept current by the home router (name not in this public repo; the Terra has it in `/etc/wireguard/wg0.conf`). The home IP is dynamic, so peers must dial the name, never an IP |
| Immich library | `/mnt/ssd_1tb/immich-library` (about 200 to 250 GB, growing) |
| Immich DB dumps | `/mnt/ssd_1tb/immich-library/backups/immich-db-backup-*.sql.gz`, made nightly at 02:00 by Immich itself |
| Phone alerts | `scripts/ntfy-push.sh "<title>"`; systemd units use `OnFailure=notify-failure@%n.service` |
| restic | 0.18.0 installed 2026-10-17; password in `/root/.config/restic/terra.pass` + Vaultwarden |

Note: despite its name, `/mnt/ssd_1tb` is a spinning WD HDD (`WD10SPZX`), and
it is the only local copy of the photos.

### What to back up

| Path under `immich-library/` | Back up? | Why |
|---|---|---|
| `library/`, `upload/`, `profile/` | yes | the originals |
| `backups/` | yes | Postgres dumps: albums, faces, metadata |
| `thumbs/`, `encoded-video/` | **no** | Immich regenerates them; they only cost space |

Also back up `/mnt/ssd/backups/` (Vaultwarden, Nextcloud, Linkwarden,
KitchenOwl, TravelSync, FreshRSS dumps; about 530 MB on 2026-10-03). It's
tiny next to the photos and gives those services a second offsite copy
besides B2.

Don't back up the live Postgres dir (`docker/immich/postgres`). Copying it
while it runs gives you a corrupt copy. The dumps in `backups/` are the DB
backup.

## Hardware

- **Hostname `cricket`**, WireGuard `10.8.0.4`.
- **Terra PC-Micro 3000 Silent Greenline** (fanless x86_64 mini PC), Debian 13
  trixie, RAM upgraded and thermal paste replaced (2026-10).
- OS on the internal 64 GB SSD. Backups go **only** on the big HDD, never the
  SSD.
- The HDD: Toshiba MQ04ABD200 2 TB (bought 2026-10, SMR) in a USB enclosure,
  seeded on lemongrab (log 2026-10-17 in `docs/reference/troubleshooting-log.md`).
  USB enclosures drop out more often than SATA; the `nofail` mount and
  `RequiresMountsFor=` keep that from writing backups onto the SSD.
- Fanless case: check the HDD temperature in SMART after a full first backup
  (keep it under about 50 °C).
- BIOS: set "restore on AC power loss" to **On**, so it boots by itself after
  an office power cut. Nobody will be there to press the button.

## Part A: on the Terra (Claude on the Terra does this)

1. **Base:** update the OS, hostname `cricket` (kept; "Terra" is the hardware), enable
   unattended security upgrades, SSH key-only login.
2. **Drive:** one GPT partition, ext4, label `offsite`. Mount at
   `/mnt/offsite` by UUID with `nofail` in `/etc/fstab`. Check SMART with
   `smartctl -H -A` and record the baseline.
   The drive is a Toshiba MQ04ABD200 2.5" laptop HDD, which parks its heads
   aggressively like lemongrab's WD did (log 2026-10-17). Stop that with APM
   254, now and on every boot (APM resets on power loss):
   `apt install hdparm`, `hdparm -B 254 /dev/disk/by-id/ata-TOSHIBA_MQ04ABD200_56HRP1HST`,
   and append the same block format `scripts/fix-hdd-head-parking.sh` writes
   (`<by-id path> {`, `apm = 254`, `}` on three lines) to `/etc/hdparm.conf`. If `hdparm -B` says unsupported through the USB
   enclosure, record `Load_Cycle_Count` and recheck after a week.
   The repo is seeded on lemongrab before the move (log 2026-10-17), so
   format nothing: just `chown -R restic-rest-server:restic-rest-server /mnt/offsite/restic`.
3. **WireGuard client:** generate the Terra's key pair on the Terra (the private key
   never leaves it). Give its **public** key to the owner so it can be
   added on lemongrab (Part B step 1). The config uses:
   - `Address = 10.8.0.4/32`
   - `[Peer]` lemongrab public key, `Endpoint = <public endpoint>:51820`
   - `AllowedIPs = 10.8.0.1/32` (only the server, not the whole home LAN)
   - `PersistentKeepalive = 25` (keeps the tunnel up behind the work NAT)

   Enable `wg-quick@wg0`. Test with `ping 10.8.0.1`. If it fails, work may
   block outbound UDP 51820, so tell the owner rather than working around
   it.
4. **rest-server:** `apt install restic-rest-server apache2-utils` (trixie
   package 0.13.0, checked 2026-10-17). It ships the binary
   `restic-rest-server`, the system user `restic-rest-server`, the unit
   `restic-rest-server.service` (reads `/etc/default/restic-rest-server`,
   refuses to start while `BACKUP_DIR` is unset) and
   `/etc/restic-rest-server/users.htpasswd` (root:restic-rest-server 0640).
   Set in `/etc/default/restic-rest-server`:
   ```
   LISTEN = 10.8.0.4:8000
   BACKUP_DIR = /mnt/offsite/restic
   ARGS = "--append-only --private-repos --htpasswd-file /etc/restic-rest-server/users.htpasswd"
   ```
   User: `htpasswd -B /etc/restic-rest-server/users.htpasswd lemongrab`, and
   hand that password to the owner. Drop-in
   `systemctl edit restic-rest-server`:
   ```
   [Unit]
   Wants=wg-quick@wg0.service
   After=wg-quick@wg0.service
   RequiresMountsFor=/mnt/offsite
   ```
   so it can bind the WireGuard IP and never writes to the OS SSD when the
   drive is missing. Then `systemctl enable --now restic-rest-server`.
5. **Firewall:** allow SSH and port 8000 only on `wg0`. Deny everything
   inbound on the work LAN interface except what the OS needs.
6. **Watchdog:** install [`watchdog.sh`](watchdog.sh) as
   `/usr/local/bin/terra-watchdog.sh` (0755), run by a oneshot
   `terra-watchdog.service` + `terra-watchdog.timer` (`OnBootSec=5min`,
   `OnUnitActiveSec=10min`). It pushes to the phone when lemongrab is offline
   (lemongrab can't report its own power or internet cut) or when no new
   restic snapshot has landed in 36 h. Put the ntfy topic URL the owner gives
   you in `/etc/terra-watchdog/ntfy_topic_url` (0600, root). That's the only
   homelab value the Terra holds, and it grants no access to lemongrab.
   Test: `sudo systemctl start terra-watchdog.service`, then
   `bash test-watchdog.sh` from this folder (takes about 3 min).
7. **Log out:** `claude logout` when done, so no session is left on a device
   in the office.

### Remote access (after setup)

SSH only, through lemongrab: `ssh -J lemongrab <user>@10.8.0.4`. No RDP and
no desktop; it's a headless box. Don't widen `AllowedIPs` or open SSH on the
work LAN to make this shorter.

To use Claude Code on the Terra remotely: `apt install tmux`, then over SSH
run `tmux new -A -s claude`, `claude`, and log in by pasting the URL/code it
prints. Log out (`claude logout`) when finished, same as step 7. A logged-in
session leaves an account token on an unencrypted disk in the office.

### Moving to another network

The Terra dials out to lemongrab's DDNS name, so its local IP and network
don't matter. The firewall isn't tied to the LAN interface, and the endpoint
is re-resolved every 5 min (`/etc/cron.d/terra-wg-reresolve`). What it needs:

- **A saved connection.** It only joins known Wi-Fi (`Intertec -Employees`,
  `POSOHIN`). Add the new one **before** the move, or on site:
  `sudo nmcli dev wifi connect "<SSID>" password "<pass>"`. That saves a
  system-wide profile that joins at boot with nobody logged in. Ethernet
  (`Wired connection 1`) connects anywhere with DHCP, no setup needed.
- **Outbound UDP 51820.** A guest network with a captive portal (login page)
  or that blocks UDP won't bring the tunnel up. Someone has to be at the box
  then. Don't work around it by opening SSH on the LAN.

Check after the move: `ping 10.8.0.1` from the Terra, or `ssh goce@10.8.0.4`
from lemongrab.

**Claude on the Terra must not:** ask for or store lemongrab SSH keys, the
restic password, or the rclone/B2 config. Its job ends at "rest-server is
listening on 10.8.0.4:8000 and survives a reboot".

## Part B: on lemongrab (done from this repo)

1. Add the Terra as a WireGuard peer in `/etc/wireguard/wg0.conf` (its public
   key, `AllowedIPs = 10.8.0.4/32`), pick a free X, `wg syncconf`.
2. `apt install restic`. Generate a restic password to
   `/root/.config/restic/terra.pass` (0600) **and save a copy in
   Vaultwarden**. Without it the backup is unreadable.
3. `restic -r rest:http://lemongrab:<pw>@10.8.0.4:8000/lemongrab/ init`
4. Script `scripts/backup-immich-terra.sh`: `restic backup` of the paths
   above (Immich and `/mnt/ssd/backups/`), `--exclude thumbs --exclude encoded-video`, exit non-zero on
   failure.
5. `backup-immich-terra.service` (`OnFailure=notify-failure@%n.service`)
   + `.timer` at 04:00 (after Immich's 02:00 dump and the 03:00 B2 sync),
   `Persistent=true`.
6. Health module `scripts/health.d/70-terra.sh`: alert if the newest
   snapshot is older than 48 h, or the repo is unreachable. Timers that
   silently stop firing are how this homelab lost 8 months of backups
   (troubleshooting log 2026-09-25).
7. Append a troubleshooting-log entry.

ponytail: no `restic forget`/`prune`, because append-only forbids it and a
photo library mostly grows. Ceiling: the repo grows forever. At 250 GB on a
1 TB drive that's years away. Upgrade path: once a year, on the Terra, restart
rest-server without `--append-only`, run `forget --keep-monthly 24 --prune`
from lemongrab, then switch it back.

## Verify (after Part B)

```bash
restic -r <repo> snapshots            # a snapshot from tonight
restic -r <repo> check --read-data-subset=5%
restic -r <repo> restore latest --target /tmp/restore-test --include '*/library/*' # spot-check a few photos open, then delete
restic -r <repo> forget --keep-last 1 # must FAIL: proves append-only works
```

Also unplug the Terra's drive once and confirm the next run pushes a failure to
the phone. From both sides: lemongrab's backup unit fails, and within 36 h the
Terra watchdog says no new backup arrived.
