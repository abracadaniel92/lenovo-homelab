# My Pi-hole was quietly sending everything to Google

**Angle:** Pi-hole v6 ignores v5 environment variables, so the compose file lied; check the effective config.

**Story beats:**
- Compose said upstream = local Unbound
- Pi-hole v6 ignored `PIHOLE_DNS_`; every query went to Google
- Found with `pihole-FTL --config dns.upstreams`
- Set the upstream in v6 config, added DNSSEC; verified with `dnssec-failed.org` SERVFAIL
- Lesson: after a major upgrade, check the effective config, not the file you wrote

**Evidence:** Pi log 2026-10-17

**Public check:** Leave out: LAN IPs

**Outline:** (filled in at approval)

**Effort:** (filled in at approval)

**Priority:** (filled in at approval)

**Published:**
