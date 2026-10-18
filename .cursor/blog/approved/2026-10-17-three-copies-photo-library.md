# Three copies of a family photo library on a homelab budget

**Angle:** B2 with rclone crypt plus restic to an office PC over WireGuard, seeded over USB.

**Story beats:**
- Photos existed only on one laptop HDD in the server
- Plan: B2 encrypted nightly plus a second offsite box
- WireGuard to an office mini PC: DDNS re-resolve cron, a key copied from a screenshot with I/l swapped
- Seed 133 GiB over USB instead of days of upload
- Lesson: offsite needs monitoring too (freshness checks, watchdog)

**Evidence:** lemongrab log 2026-09-26 (B2 audit + B2 offsite), lemongrab log 2026-10-17 (Terra seed), Terra log 2026-10-05

**Public check:** Leave out: employer name and Wi-Fi name, DDNS hostname, WireGuard keys and IPs

**Outline:**
1. 10 years of photos on one laptop HDD in the server
2. Copy 2: B2 with rclone crypt, nightly
3. Copy 3: restic to an office mini PC over WireGuard (DDNS re-resolve, the I/l key from a screenshot)
4. Seeding 133 GiB over USB instead of days of upload
5. Offsite needs monitoring too: freshness checks, watchdog

**Effort:** post (long)

**Priority:** soon (write after the new backup drive is online, planned 2026-10-19, so the story has its ending)

**Published:**
