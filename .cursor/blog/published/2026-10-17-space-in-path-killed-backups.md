# A space in a path killed my backups for 8 months, and my health check never noticed

**Angle:** Unquoted paths fail silently in cron and systemd; how to find it, why a symlink with no spaces was the fix, and the audit that showed the health check could never have caught it.

**Story beats:**
- Health checks, backups and auto-recovery all looked configured
- Every unquoted caller broke on the space in the repo path, silently, for eight months
- Found while auditing why nothing had alerted
- Fix: `/opt/homelab` symlink and quoting; a check that would now fail loudly
- Then audited the monitoring itself: the probe could not see 5xx, two checks could never fire
- Fixes plus tests that force each check to fail
- Last gap: every alert ran on the box it watched; added a healthchecks.io dead man's switch pinged at the end of each hourly run
- Lesson: a check you've never seen fail is not a check; test that your monitoring can fail

**Evidence:** lemongrab log 2026-09-25, lemongrab log 2026-09-26 ("Audit of the health-check modular migration", "Review of the 2026-09-25 repair"), lemongrab log 2026-10-08 (healthchecks.io)

**Merged from:** health-check-could-never-fail (2026-10-18). who-watches-the-watchman was merged in, then split back out the same day (not in the published post).

**Public check:** No secrets; real path is fine. Leave out: the healthchecks.io ping URL

**Outline:**
1. Everything looked configured: health checks, backups, auto-recovery
2. One space in the repo path broke every unquoted caller, silently, for 8 months
3. How it was found, and the fix: `/opt/homelab` symlink plus quoting
4. Twist: auditing the monitor (blind to 5xx, two checks that could never fire)
5. Tests that force each check to fail
6. Who watches the watchman: an external dead man's switch (healthchecks.io)
7. A check you've never seen fail is not a check; at least one must live outside the box

**Effort:** post (long, ~1800 words)

**Priority:** next (backstory for git-checkout-is-a-deploy; publish before or with it)

**Published:** 2026-10-08, https://gmojsoski.com/blog/space-in-path-killed-homelab-automation (written before this candidate existed; covers the outage, the health-check audit and the `git checkout` paragraph, NOT the dead man's switch)
