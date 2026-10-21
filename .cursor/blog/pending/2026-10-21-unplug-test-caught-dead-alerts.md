# The unplug test that caught the alerts, not the backup

- Hook: I unplugged the offsite drive to prove the backup would complain. The backup failed fine. The alert about it was the thing that was broken.
- Root cause: Cloudflare started answering Python's default `Python-urllib` User-Agent with 403 error 1010. Every Mattermost failure alert since then was dropped, silently. curl with the same URL worked.
- Fix: one header (`User-Agent: lemongrab-notify-unit-failure`).
- Lesson: test the alarm, not only the thing it guards. A failure test that only checks "did it fail" misses half the point.
- Source: docs/reference/troubleshooting-log.md 2026-10-21, commit ecfacb8.
