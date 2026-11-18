**Proposed change:** In `terra/README.md` Part A step 2 (APM) and in
`scripts/fix-hdd-head-parking.sh`'s header, add: "`/etc/hdparm.conf` is not applied to
USB-attached disks: Debian's hdparm udev hook skips APM for `pci-*-usb-*` paths. Use a
udev rule keyed on the drive serial (`ENV{ID_SERIAL_SHORT}`) that runs `hdparm -B 254`.
Verify after a cold power cycle or replug, not a warm reboot."

**Why now:** the 2026-10-19 Terra entry concluded "`/etc/hdparm.conf` is applied at boot
through the Verbatim enclosure. No udev rule needed." That was wrong: the warm reboot kept
the enclosure powered, so the drive just kept 254. The 2026-10-21 unplug test came back
with `APM_level = 128`.

**Evidence:** Terra log 2026-10-21; `/usr/lib/hdparm/hdparm-functions` `hdparm_try_apm`.

**Scope:** the two docs above. The udev rule itself is a separate change.

**Boundaries:** don't edit the 2026-10-19 log entry (append-only); the new entry corrects it.
