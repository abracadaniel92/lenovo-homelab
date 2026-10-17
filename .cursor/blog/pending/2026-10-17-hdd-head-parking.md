# 282k head parks: a laptop drive running 24/7

**Angle:** Laptop HDDs park their heads every couple of minutes; on a server that wears them out in a year or two. One hdparm line.

**Story beats:**
- SMART showed Load_Cycle_Count 282k after 9.4k hours (rated ~600k)
- Power saving parked the heads ~30 times an hour
- Spotted in a routine SMART read
- `hdparm -B 254` persisted in `/etc/hdparm.conf`: +0 cycles in 215 min
- Lesson: check Load_Cycle_Count on any 2.5" drive you run 24/7

**Evidence:** lemongrab log 2026-10-17 ("Immich HDD head parking stopped")

**Public check:** Nothing

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
