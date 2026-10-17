# Blog ideas

Homelab work that would make a good post on gmojsoski.com. Added by the agent
(see `CLAUDE.md` habit 7) or by hand. One line each: title, angle, and the
troubleshooting-log entry date to write it from. Public: no secrets or IPs.

- A space in a path killed my backups for 8 months: unquoted callers, silent cron failures, and the symlink fix (log 2026-09-25)
- My health check could never fail: auditing monitoring that can't see 5xx, and checks that could never fire (log 2026-09-26)
- Restore drills: "backup succeeded" while Linkwarden's backups had no database (log 2026-09-26)
- Three copies for a family photo library: B2 with rclone crypt, plus restic to an office PC over WireGuard (DDNS re-resolve cron, a key copied from a screenshot with I/l swapped), seeded over USB (log 2026-09-26, 2026-10-17, Terra log 2026-10-05)
- 282k head parks: a laptop HDD running 24/7 and one hdparm line (log 2026-10-17)
- My Pi-hole was quietly sending everything to Google: v5 env vars that v6 ignores, and checking effective config instead of compose (Pi log 2026-10-17)
- When `git checkout` is a deploy: a branch switch nearly killed DNS for the house, and the symlink that makes lemongrab's scripts live (Pi log 2026-10-03, log 2026-09-25)
- Who watches the watchman: a healthchecks.io dead man's switch for a server that only alerted on itself (log 2026-10-08)
- Life after Watchtower: weekly update list, manual pulls, and rate-limiting myself on Docker Hub (log 2026-09-26, 2026-10-05)
- TIL: `caddy validate` was checking the old file (single-file bind mounts keep the old inode) (log 2026-10-08)
- Keeping a Raspberry Pi alive on an SD card: zram writeback, Pi-hole DB interval, log caps, and an unused WARP eating 20% of RAM (Pi log 2026-10-13, 2026-10-17)
