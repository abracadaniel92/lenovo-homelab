# Head parking, part two: the fix that didn't reach a USB disk

**Angle:** Follow-up to the approved head-parking post: the same `hdparm -B 254` fix on a USB drive failed twice silently, and the parks that remained came from software that block I/O stats can't see.

**Story beats:**
- Same laptop-drive fix as lemongrab, on the offsite backup drive in a USB enclosure; a reboot test said it stuck
- An unplug test showed APM back at 128: Debian's hdparm udev hook skips USB disks, so `/etc/hdparm.conf` never applied. The reboot only "passed" because the enclosure stayed powered.
- Fix: a udev rule keyed on the drive serial; proven by a real cable pull
- Still ~7 parks/h at APM 254, with zero reads and writes for a whole hour
- Cause: SMART polls (udisks2 every 10 min, smartd every 30) are drive accesses that block stats don't count
- smartd went to 3 h; udisks2's poll can't be turned off per drive (two udev tricks tested and failed), so ~6/h was accepted (~53k/yr against a ~600k rating)
- Lessons: test persistence with a power cut, not a warm reboot; "no I/O" in `/sys/block/*/stat` doesn't mean nothing touched the drive; know when a wear rate is good enough

**Evidence:** Terra log 2026-10-21 (entries "unplug test passed on both sides; APM lost on replug", "second unplug test", "parking traced to SMART polling", "udisks2 SMART polling can't be switched off per drive"); commits 55449d0, d66ab1f, 4425059.

**Public check:** Leave out: drive serial, WireGuard IPs, DDNS name, where the Terra sits (an office network).

**Outline:**

**Effort:**

**Priority:**

**Published:**
