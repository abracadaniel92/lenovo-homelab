# The backup box that "crashed" three times and never crashed

**Angle:** `last -x` saying `crash` doesn't mean the kernel crashed. Here a
flaky Wi-Fi firmware hung the shutdowns, and the readings that pointed at the
disk and at sshd were wrong.

**Story beats:**
- Symptom: the offsite backup box was slow over SSH, looked stuck on boot, and
  `last -x` showed three crashes in two weeks. The obvious suspects were the
  USB backup drive, power cuts and sshd.
- sshd was cleared first: a local handshake took 0.3 s. The network was the
  problem, with 70-85 % packet loss in bursts.
- The system journal showed that every "crash" was an orderly reboot or
  power-off whose final stage never finished. Each of today's two shutdowns
  came ~30 s after an Intel Wi-Fi firmware assert (`ADVANCED_SYSASSERT`, then
  "Failing on timeout while stopping DMA").
- The proof was on the disks: at the next boot the backup drive's ext4 needed
  "recovering journal", the EFI partition had its dirty bit set, and the
  drive's power-off-retract counter rose by 2. SMART was clean and the backups
  were intact.
- The firmware is already the last one Intel shipped for this card (`-46`), so
  there's nothing to upgrade. The mitigations are Wi-Fi power save off now and
  Ethernet as the real fix. Include a before/after if a week on power-save-off
  shows no new asserts.
- Lessons: read the end of each boot's journal before believing `crash`. A
  journal that ends cleanly with "Journal stopped" means the hang came after
  logging stopped. A cheap Wi-Fi card can take the whole shutdown down with it.

**Evidence:** Terra log 2026-11-12 (both entries: "slow SSH is Wi-Fi packet
loss" and "Wi-Fi firmware crashes precede each shutdown; shutdowns hang"),
plus the follow-up entry with the firmware check; commits 2f979a7, 1e6602c.

**Public check:** Leave out: the employer and its Wi-Fi network name, the
office location, WireGuard IPs, the DDNS name, the WireGuard peer key (it
appears in the cron journal lines), drive serials.

**Outline:**

**Effort:**

**Priority:**

**Published:**
