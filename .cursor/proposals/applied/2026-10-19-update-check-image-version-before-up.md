**Proposed change:** In `.cursor/skills/update-homelab-service/SKILL.md`, step 6, after
`docker compose pull`, add: "Before `up -d`, read the version of the image you just pulled
(`docker image inspect <image> --format '{{index .Config.Labels "org.opencontainers.image.version"}}'`,
or run its `--version`). That, not GitHub's "latest release", is what will run. If it is a new
major version, stop and read that version's upgrade notes first."

**Why now:** Mattermost was planned as 11.11.1 -> 11.11.2 because GitHub's `releases/latest`
said 11.11.2 (a patch to the old line, published hours earlier). Docker `:latest` was already
12.0.0, so `up -d` did a major upgrade with DB migrations before its notes were read.

**Evidence:** 2026-10-19 on lemongrab. It ended well (Postgres 15 meets the new minimum, no
OpenSearch, used plugins are prepackaged), but the notes were read after the fact.

**Scope:** `update-homelab-service/SKILL.md` step 6 only.

**Boundaries:** No new script; does not change `update-check.sh`.
