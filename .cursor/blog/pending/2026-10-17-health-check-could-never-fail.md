# My health check could never fail

**Angle:** Auditing monitoring itself: a probe that couldn't see 5xx and checks that could never fire.

**Story beats:**
- The modular health check reported green
- The probe could not see 5xx; two checks could never fire
- Found by a deliberate audit after the path outage
- Fixes plus tests that force each check to fail
- Lesson: a check you've never seen fail is not a check

**Evidence:** lemongrab log 2026-09-26 ("Audit of the health-check modular migration", "Review of the 2026-09-25 repair")

**Public check:** Nothing

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
