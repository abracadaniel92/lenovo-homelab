# Who watches the watchman? A dead man's switch for a homelab

**Angle:** Every alert ran on the server it was watching; an external ping turns silence into an alert.

**Story beats:**
- All alerting lived on lemongrab itself
- A dead timer, server or uplink would go silent (as the 8-month outage did)
- healthchecks.io pinged at the end of each hourly run
- Alert fires when the ping stops
- Lesson: at least one check must live outside the box

**Evidence:** lemongrab log 2026-10-08

**Public check:** Leave out: the ping URL

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
