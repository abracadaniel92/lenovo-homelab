# Terra: offsite backup box at work

**Status:** planned, not built yet (written 2026-09-27).

The Terra, a small PC at the office (see Hardware), holds a second offsite copy of the Immich photo
library. With Backblaze B2 that makes three copies: lemongrab, the Terra, B2.
Work has approved the Terra on their network.

This doc is the brief for whoever sets it up, including Claude Code running
on the Terra. **Part A runs on the Terra. Part B runs on lemongrab.** Don't mix them
up: the Terra must never get access to lemongrab.

## Design

```
lemongrab (10.8.0.1)  --restic over WireGuard-->  Terra (10.8.0.X)
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
| Public endpoint | **TODO:** home IP or DDNS name the Terra dials |
| Immich library | `/mnt/ssd_1tb/immich-library` (about 200 to 250 GB, growing) |
| Immich DB dumps | `/mnt/ssd_1tb/immich-library/backups/immich-db-backup-*.sql.gz`, made nightly at 02:00 by Immich itself |
| Phone alerts | `scripts/ntfy-push.sh "<title>"`; systemd units use `OnFailure=notify-failure@%n.service` |
| restic | not installed yet |

Note: despite its name, `/mnt/ssd_1tb` is a spinning WD HDD (`WD10SPZX`), and
it is the only local copy of the photos.

### What to back up

| Path under `immich-library/` | Back up? | Why |
|---|---|---|
| `library/`, `upload/`, `profile/` | yes | the originals |
| `backups/` | yes | Postgres dumps: albums, faces, metadata |
| `thumbs/`, `encoded-video/` | **no** | Immich regenerates them; they only cost space |

Don't back up the live Postgres dir (`docker/immich/postgres`). Copying it
while it runs gives you a corrupt copy. The dumps in `backups/` are the DB
backup.

## Hardware

- **Terra PC-Micro 3000 Silent Greenline** (fanless x86_64 mini PC), Debian 13
  trixie, RAM upgraded and thermal paste replaced (2026-10).
- OS on the internal 64 GB SSD. Backups go **only** on the big HDD, never the
  SSD.
- The HDD: the new 1 TB drive or a bigger one. If it's the 1 TB, it's first used
  as the clone target for recovering the failing old 1 TB drive, so wipe it
  only after that recovery is finished. Prefer an internal SATA bay if the case
  has one; USB enclosures drop out more often.
- Fanless case: check the HDD temperature in SMART after a full first backup
  (keep it under about 50 °C).
- BIOS: set "restore on AC power loss" to **On**, so it boots by itself after
  an office power cut. Nobody will be there to press the button.

## Part A: on the Terra (Claude on the Terra does this)

1. **Base:** update the OS, set the hostname (e.g. `terra`), enable
   unattended security upgrades, SSH key-only login.
2. **Drive:** one GPT partition, ext4, label `offsite`. Mount at
   `/mnt/offsite` by UUID with `nofail` in `/etc/fstab`. Check SMART with
   `smartctl -H -A` and record the baseline.
3. **WireGuard client:** generate the Terra's key pair on the Terra (the private key
   never leaves it). Give its **public** key to the owner so it can be
   added on lemongrab (Part B step 1). The config uses:
   - `Address = 10.8.0.X/32` (X assigned in Part B)
   - `[Peer]` lemongrab public key, `Endpoint = <public endpoint>:51820`
   - `AllowedIPs = 10.8.0.1/32` (only the server, not the whole home LAN)
   - `PersistentKeepalive = 25` (keeps the tunnel up behind the work NAT)

   Enable `wg-quick@wg0`. Test with `ping 10.8.0.1`. If it fails, work may
   block outbound UDP 51820, so tell the owner rather than working around
   it.
4. **rest-server:** `apt install restic-rest-server` (packaged in
   trixie). Run it as a dedicated
   `restic` system user via systemd:
   ```
   rest-server --path /mnt/offsite/restic --listen 10.8.0.X:8000 \
               --append-only --private-repos --htpasswd-file /etc/rest-server/.htpasswd
   ```
   Create one htpasswd user `lemongrab` and hand its password to the owner.
   The unit must start `After=wg-quick@wg0.service` and
   `RequiresMountsFor=/mnt/offsite`, so it never writes to the OS SSD when
   the drive is missing.
5. **Firewall:** allow SSH and port 8000 only on `wg0`. Deny everything
   inbound on the work LAN interface except what the OS needs.
6. **Log out:** `claude logout` when done, so no session is left on a device
   in the office.

**Claude on the Terra must not:** ask for or store lemongrab SSH keys, the
restic password, or the rclone/B2 config. Its job ends at "rest-server is
listening on 10.8.0.X:8000 and survives a reboot".

## Part B: on lemongrab (done from this repo)

1. Add the Terra as a WireGuard peer in `/etc/wireguard/wg0.conf` (its public
   key, `AllowedIPs = 10.8.0.X/32`), pick a free X, `wg syncconf`.
2. `apt install restic`. Generate a restic password to
   `/root/.config/restic/terra.pass` (0600) **and save a copy in
   Vaultwarden**. Without it the backup is unreadable.
3. `restic -r rest:http://lemongrab:<pw>@10.8.0.X:8000/lemongrab/ init`
4. Script `scripts/backup-immich-terra.sh`: `restic backup` of the paths
   above, `--exclude thumbs --exclude encoded-video`, exit non-zero on
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
the phone.
