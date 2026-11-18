# 282k head parks: a laptop drive running 24/7

**Angle:** Laptop HDDs park their heads every couple of minutes; on a server that wears them out in a year or two. One hdparm line fixes it on SATA. On a USB disk the same fix failed silently twice, and the parks that remained came from software that block I/O stats can't see. (Merged 2026-11-18 with the "part two: USB disk" candidate.)

**Story beats:**
- SMART showed Load_Cycle_Count 282k after 9.4k hours (rated ~600k)
- Power saving parked the heads ~30 times an hour
- Spotted in a routine SMART read
- `hdparm -B 254` persisted in `/etc/hdparm.conf`: +0 cycles in 215 min
- Same fix on the offsite backup drive in a USB enclosure; a reboot test said it stuck
- An unplug test showed APM back at 128: Debian's hdparm udev hook skips USB disks, so `/etc/hdparm.conf` never applied. The reboot only "passed" because the enclosure stayed powered.
- Fix: a udev rule keyed on the drive serial; proven by a real cable pull
- Still ~7 parks/h at APM 254, with zero reads and writes for a whole hour
- Cause: SMART polls (udisks2 every 10 min, smartd every 30) are drive accesses that block stats don't count
- smartd went to 3 h; udisks2's poll can't be turned off per drive (two udev tricks tested and failed), so ~6/h was accepted (~53k/yr against a ~600k rating)
- Lessons: check Load_Cycle_Count on any 2.5" drive you run 24/7; test persistence with a power cut, not a warm reboot; "no I/O" in `/sys/block/*/stat` doesn't mean nothing touched the drive; know when a wear rate is good enough

**Evidence:** lemongrab log 2026-10-17 ("Immich HDD head parking stopped"); Terra log 2026-10-21 (entries "unplug test passed on both sides; APM lost on replug", "second unplug test", "parking traced to SMART polling", "udisks2 SMART polling can't be switched off per drive"); commits 55449d0, d66ab1f, 4425059.

**Public check:** Leave out: drive serial, WireGuard IPs, DDNS name, where the Terra sits (an office network).

**Outline:**
1. 282k head parks after 9.4k hours (rated ~600k), and why laptop power saving does it
2. The fix: `hdparm -B 254` in `/etc/hdparm.conf`; proof: +0 cycles in 215 minutes
3. Same fix on a USB disk: a reboot said it stuck, a cable pull said it didn't (Debian's udev hook skips USB)
4. The udev rule on the drive serial, proven by a real power cut
5. Still parking with zero I/O: SMART polls block stats can't see, and when ~6/h is good enough
6. Checklist: Load_Cycle_Count on any 24/7 2.5" drive; test with a power cut, not a reboot

**Effort:** post

**Priority:** soon

**Published:**

Note: the existing draft in portfolio_v2 `blog/drafts/laptop-hdd-head-parking-24-7.md` covers beats 1-4 only; the USB half still needs writing.
