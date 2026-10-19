**Proposed change:** `.cursor/skills/update-homelab-service/SKILL.md`, the paragraph "Docker
Hub allows 100 anonymous requests per hour...". Append: "`update-check.sh` spends about 30 of
them per run, so run it once, not repeatedly, right before pulling. If a pull hits 429, wait
for the refill or pull via `mirror.gcr.io`."

**Why now:** The quota is explained, but not that the agent's own check burns it.

**Evidence:** 2026-10-05 lemongrab log: three back-to-back `update-check.sh` runs used up the
quota and both planned pulls failed with 429; the entry's own "Lesson" says so and names
`mirror.gcr.io` as the approved fallback. 2026-10-13: Stirling PDF update skipped, 429 again.

**Scope:** `.cursor/skills/update-homelab-service/SKILL.md`

**Boundaries:** One added sentence to the existing paragraph.
