# The container my update checker couldn't see: a local build a major version behind

**Angle:** A tiny local Dockerfile patch on top of an upstream `:latest` image quietly opts that service out of every update: `compose pull` skips it and a digest-based update checker skips it too. Paperless sat on 2.20.15 while upstream reached 3.5.1.

**Story beats:**
- Weekly update list said "not checked" for nothing; Paperless simply never appeared
- Why: `build: .` + `FROM paperless-ngx:latest` means no registry digest to compare; `docker compose pull` doesn't rebuild
- The patch itself (a DB timezone fix) would have broken on v3 anyway: `settings.py` became `settings/__init__.py`
- Upgrade: backup DB + volumes, check each v3 breaking change against the config, make the patch anchor version-proof, `build --pull`
- Fix in the checker: compare the running container's inherited `org.opencontainers.image.revision` label with the registry's for the Dockerfile's `FROM`; plus flag containers running a bare image ID (pulled but never recreated)
- Gotcha found while testing: after a buildx rebuild the local image gets a digest, and the registry lookup says "does not exist", so the first version of the fix skipped it again
- Lessons: every local patch is an update you now own; check what your checker skips, not just what it reports

**Evidence:** lemongrab log 2026-11-18 ("Paperless 2.20.15 -> 3.5.1", "update-check.sh: catch stale local builds"); commits a45cefb, 44bcc10.

**Public check:** Nothing sensitive; leave out the DB credentials and the shared Nextcloud Postgres hostname details.

**Outline:**

**Effort:**

**Priority:**

**Published:**
