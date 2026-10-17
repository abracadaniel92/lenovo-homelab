**Proposed change:** `CLAUDE.md`, section "FIRST: figure out which machine you're on". It lists
only lemongrab and the Windows dev machine. Add two bullets:
- **On the Pi (`pihole`):** the checkout is also live for DNS. Unbound bind-mounts
  `pihole/docker/unbound/unbound.conf` from it, so a branch switch or pull that touches that
  folder needs `cd pihole/docker/unbound && docker compose up -d` afterwards. Never use
  `docker/uptime-kuma/` there (that is lemongrab's); the Pi's is `pihole/docker/uptime-kuma/`.
  Log in `pihole/troubleshooting-log.md`.
- **On the Terra (`cricket`):** follow `terra/README.md` "Start here"; never format or write
  into the offsite drive. Log in `terra/troubleshooting-log.md`.

**Why now:** Claude sessions have run on the Pi and the Terra since early October, and the file
gives them no machine-specific rules.

**Evidence:** 2026-10-03 (Pi log): `git checkout main` on the Pi deleted the old
`unbound.conf` path while Unbound was running from it; the next restart would have taken down
DNS for the whole network. 2026-10-17 (Pi log): lesson "Do not use `docker/uptime-kuma/` on
the Pi". Both lessons live only in the Pi log and `pihole/README.md`.

**Scope:** `CLAUDE.md`

**Boundaries:** Two short bullets in that one section. Does not copy the Pi or Terra runbooks
into `CLAUDE.md`.
