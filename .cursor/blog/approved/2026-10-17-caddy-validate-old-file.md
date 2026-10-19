# TIL: caddy validate was checking the old file

**Angle:** Single-file Docker bind mounts keep the old inode after you edit the file.

**Story beats:**
- Edited the Caddyfile, validate passed
- The container still saw the old file; editors replace the inode
- Caught while adding Caddy access logs
- Validate a `docker cp` copy, then restart; mount directories, not single files
- Lesson: single-file bind mounts and editors don't mix

**Evidence:** lemongrab log 2026-10-08 (Gotcha)

**Public check:** Nothing

**Outline:**
1. The edit that validate said was fine
2. Why the container still saw the old file (editors replace the inode)
3. How it showed up (adding Caddy access logs)
4. The fix: validate a `docker cp` copy, then restart
5. The rule: mount directories, not single files

**Effort:** TIL

**Priority:** someday

**Published:**
