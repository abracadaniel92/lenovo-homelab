# Troubleshooting Log: Pi (pihole)

Changes, incidents and fixes on the Raspberry Pi 4 (Pi-hole, Unbound, secondary
Uptime Kuma). Newest first. Same format as the lemongrab log at
[`docs/reference/troubleshooting-log.md`](../docs/reference/troubleshooting-log.md);
the Terra has its own at [`terra/troubleshooting-log.md`](../terra/troubleshooting-log.md).
Pi entries from before 2026-10-03 are in the lemongrab log.

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
