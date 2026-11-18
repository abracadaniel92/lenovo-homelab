**Proposed change:** In `CLAUDE.md` "Known drift / open items", replace the
`docker/caddy/site/` bullet's description of the live pipeline with: "The live
gmojsoski.com is served by Cloudflare Workers static assets (project
`my-portfolio`), deployed on every push to `portfolio_v2` `main`.
`scripts/update-portfolio.sh` / `make portfolio-update` only refresh the
homelab fallback copy in `/srv/site`." Same correction for the
`make portfolio-update` line under Commands.

**Why now:** CLAUDE.md still says the live site is built by
`update-portfolio.sh` and synced to Caddy. Since 2026-11-06 that is the
fallback; an agent following it would "deploy" to a copy nobody sees.

**Evidence:** lemongrab log 2026-11-06 "gmojsoski.com moved off the homelab".

**Scope:** CLAUDE.md only.
