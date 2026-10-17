# A space in a path killed my backups for 8 months

**Angle:** Unquoted paths fail silently in cron and systemd; how to find it, and why a symlink with no spaces was the fix.

**Story beats:**
- Health checks, backups and auto-recovery all looked configured
- Every unquoted caller broke on the space in the repo path, silently, for eight months
- Found while auditing why nothing had alerted
- Fix: `/opt/homelab` symlink and quoting; a check that would now fail loudly
- Lesson: test that your monitoring can fail

**Evidence:** lemongrab log 2026-09-25 (and the two 2026-09-26 reviews)

**Public check:** Nothing beyond the usual: no secrets; real path is fine

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
