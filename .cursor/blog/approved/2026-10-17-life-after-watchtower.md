# Life after Watchtower: manual updates on purpose

**Angle:** Replacing auto-updates with a weekly list, and the traps of doing it by hand.

**Story beats:**
- Watchtower hadn't run in months and is unmaintained
- A weekly ntfy list of images with newer builds, then one service at a time
- Rate-limited myself on Docker Hub by checking three times
- `up -d` that didn't switch images, compose profiles that hide services
- Lesson: manual is fine if the checklist is honest

**Evidence:** lemongrab log 2026-09-25, 2026-09-26, 2026-10-05, 2026-10-12

**Public check:** Leave out: ntfy topic

**Outline:**
1. Watchtower stopped running months ago, and it's unmaintained
2. The replacement: a weekly ntfy list of newer images, one service at a time
3. Trap 1: rate-limiting myself on Docker Hub
4. Trap 2: `up -d` that didn't switch images; compose profiles that hide services
5. The checklist that keeps manual updates honest

**Effort:** post

**Priority:** soon

**Published:**
