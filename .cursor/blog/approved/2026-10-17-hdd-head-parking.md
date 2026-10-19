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

**Outline:**
1. 282k head parks after 9.4k hours (rated ~600k)
2. Why: laptop power saving parks the heads ~30 times an hour
3. The fix: `hdparm -B 254`, persisted in `/etc/hdparm.conf`
4. Proof: +0 cycles in 215 minutes
5. Check this on any 2.5" drive you run 24/7

**Effort:** TIL

**Priority:** soon

**Published:**
