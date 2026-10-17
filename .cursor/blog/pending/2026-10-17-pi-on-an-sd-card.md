# Keeping a Raspberry Pi alive on an SD card

**Angle:** Where the writes actually come from, and an unused VPN client eating 20% of RAM.

**Story beats:**
- The Pi runs DNS for the house from an SD card
- zram writeback was paging to a swap file on the card; Pi-hole wrote its DB every minute
- WARP, never registered, used ~750 MB
- zram-only swap, DB interval 30 min, log caps, WARP removed, nightly backup
- Lesson: measure writes before buying a 'high endurance' card

**Evidence:** Pi log 2026-10-13, Pi log 2026-10-17 (two entries)

**Public check:** Leave out: LAN IPs

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
