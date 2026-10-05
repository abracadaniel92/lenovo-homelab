# Troubleshooting Log: Terra (offsite backup box)

Changes, incidents and fixes on the Terra. Newest first. Same format as the
lemongrab log at [`docs/reference/troubleshooting-log.md`](../docs/reference/troubleshooting-log.md);
the Pi has its own at [`pihole/troubleshooting-log.md`](../pihole/troubleshooting-log.md).

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
