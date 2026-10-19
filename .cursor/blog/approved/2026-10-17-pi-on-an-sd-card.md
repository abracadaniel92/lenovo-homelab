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

**Outline:**
1. The house's DNS runs from an SD card
2. Where the writes came from: zram writeback to a swap file on the card, Pi-hole DB every minute
3. The fixes: zram-only swap, DB interval 30 min, log caps, nightly backup
4. Bonus find: an unregistered WARP client using ~750 MB RAM
5. Measure writes before buying a 'high endurance' card

**Effort:** post

**Priority:** soon

**Published:**
