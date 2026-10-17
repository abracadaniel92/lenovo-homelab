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

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
