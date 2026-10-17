# Backup succeeded, but there was no database in it

**Angle:** Why "backup OK" isn't enough: restore drills found Linkwarden backups with no database for months.

**Story beats:**
- Backups ran and wrote a verified archive every night
- Linkwarden's archives never contained its database
- Found by a restore drill for all five services
- `restore-drill.sh` opens each backup and checks the data is really there
- Lesson: verify contents, not just that a file was written

**Evidence:** lemongrab log 2026-09-26 ("Restore drills for all 5 services")

**Public check:** Nothing

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
