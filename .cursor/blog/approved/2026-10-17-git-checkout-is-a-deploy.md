# When `git checkout` is a deploy

**Angle:** If services read config from your git working tree, a branch switch is a production change.

**Story beats:**
- Configs and scripts run straight from the repo checkout
- A branch switch on the Pi deleted the file Unbound was running from; the next restart would have killed DNS
- On the server, checking out an old branch reverted the backup script
- Rules: keep the tree on main, commit directly there, verify after any branch operation
- Lesson: know which of your directories are live

**Evidence:** Pi log 2026-10-03, lemongrab log 2026-09-25

**Public check:** Nothing

**Outline:**
1. My repo checkout is production (bind mounts, the /opt/homelab symlink)
2. The Pi: a branch switch deleted the file Unbound was running from
3. The server: an old branch silently reverted the backup script
4. Rules now: stay on main, commit there, verify after any branch operation
5. How to find which of your directories are live

**Effort:** post

**Priority:** next (target: publish by end of October 2026)

**Published:**
