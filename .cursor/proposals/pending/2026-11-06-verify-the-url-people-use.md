**Proposed change:** In `CLAUDE.md` "Non-negotiable habits", add: "After
changing a service's config, verify the URL people actually use (a public
booking page, a share link, a file), not just the subdomain root. A login
redirect at `/` (Cal, Immich, Paperless...) proves only that the app is up."
Same line in the `update-homelab-service` and `troubleshoot-service-down`
skills' verification steps.

**Why now:** on 2026-09-27 the Cal `ALLOWED_HOSTNAMES` change was verified
with "https://cal.gmojsoski.com returns 307 (login redirect)". That 307 was
returned before and after the change; the public booking link had broken and
stayed broken for six weeks. `verify-services.sh` accepts 307 for the same
reason, so it could not catch it either.

**Evidence:** lemongrab log 2026-09-27 (Cal ALLOWED_HOSTNAMES) and 2026-11-06
(Cal booking link 404). Safety net added the same day:
`scripts/health.d/80-public-links.sh`.

**Scope:** CLAUDE.md and the two skills.
