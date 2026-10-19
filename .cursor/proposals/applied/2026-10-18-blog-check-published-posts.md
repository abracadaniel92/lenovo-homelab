**Proposed change:** `.cursor/skills/blog-review/SKILL.md`, step 1 "List the queue". Add: "Also
grep the published and draft posts in the `portfolio_v2` repo (`blog/*.md`, `blog/drafts/*.md`)
for each candidate's key terms. A candidate already told there is not new: say which post and
how much it covers (whole story, one paragraph, or a link-worthy mention) before asking."

**Why now:** The 2026-10-18 weekly review approved a candidate that was already published, and
two others whose core is a paragraph in a published post. Nobody checked the blog itself.

**Evidence:** 2026-10-18. `space-in-path-killed-backups` was approved as "next" (with two other
candidates merged into it), but `portfolio_v2/blog/space-in-path-killed-homelab-automation.md`
was published 2026-10-08 and also covers the health-check audit and `git checkout` being a deploy.
The Linkwarden restore-drill story is a paragraph in `self-hosting-homelab-resilience.md`. Found
only when the owner asked to check portfolio_v2 after the review.

**Scope:** `.cursor/skills/blog-review/SKILL.md`

**Boundaries:** Only adds the overlap check to step 1. Does not change `blog-capture.mdc`
(a separate proposal if wanted) or the approval bar.
