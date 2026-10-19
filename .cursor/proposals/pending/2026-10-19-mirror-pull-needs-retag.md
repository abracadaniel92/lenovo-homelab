**Proposed change:** In `.cursor/skills/update-homelab-service/SKILL.md`, the Docker Hub
paragraph, after "pull via `mirror.gcr.io`", add: "Compose won't see it under that name:
`docker pull mirror.gcr.io/library/<img>:<tag> && docker tag mirror.gcr.io/library/<img>:<tag> <img>:<tag>`
(non-official images drop `library/`, e.g. `mirror.gcr.io/cloudflare/cloudflared`), then `up -d`."

**Why now:** On 2026-10-19 `docker compose pull` hit 429 and printed `Running`, leaving the old
image in place silently. Five Docker Hub images (nginx, caddy, cloudflared, mattermost, nextcloud)
needed the pull+tag dance.

**Evidence:** 2026-10-19 on lemongrab; the pull+tag pattern worked for all five.

**Scope:** `update-homelab-service/SKILL.md`, Docker Hub paragraph only.

**Boundaries:** No helper script.
