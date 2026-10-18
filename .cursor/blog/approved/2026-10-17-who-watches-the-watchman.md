# Who watches the watchman? A dead man's switch for a homelab

**Angle:** Follow-up to the published space-in-path post: every alert ran on the server it was watching; an external ping turns silence into an alert.

**Story beats:**
- Recap in two lines, link to /blog/space-in-path-killed-homelab-automation
- All alerting lived on lemongrab itself
- A dead timer, server or uplink would go silent (as the 8-month outage did)
- healthchecks.io pinged at the end of each hourly run
- Alert fires when the ping stops
- Lesson: at least one check must live outside the box

**Evidence:** lemongrab log 2026-10-08

**Public check:** Leave out: the ping URL

**Outline:**
1. The outage nobody was told about (link to the published post)
2. Why: every alert ran on the box it watched
3. healthchecks.io pinged at the end of each hourly run
4. Silence becomes the alert
5. At least one check must live outside the box

**Effort:** TIL

**Priority:** soon

**Published:**
