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

**Outline:**
1. The compose file said: upstream = my local Unbound
2. Pi-hole v6 ignores `PIHOLE_DNS_`; every query went to Google
3. The one command that shows the truth: `pihole-FTL --config dns.upstreams`
4. The fix: upstream in the v6 config, DNSSEC on, `dnssec-failed.org` returns SERVFAIL
5. After a major upgrade, check the effective config, not the file you wrote

**Effort:** post (short)

**Priority:** next, first in the queue (strongest fully new story)

**Published:** https://gmojsoski.com/blog/pihole-v6-ignored-unbound-upstream (2026-10-21)
