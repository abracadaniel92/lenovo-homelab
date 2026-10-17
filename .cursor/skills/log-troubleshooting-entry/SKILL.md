---
name: log-troubleshooting-entry
description: Add a properly-formatted entry to the right device's troubleshooting log (lemongrab, Pi or Terra) following the project's entry template. Use when the user says "log this fix", "add a troubleshooting entry", "document this incident", "log to the troubleshooting log", or after a non-standard fix has been applied and should be preserved as a learning record.
---

# Log Troubleshooting Entry

Each device has its own log: lemongrab `docs/reference/troubleshooting-log.md`, Pi `pihole/troubleshooting-log.md`, Terra `terra/troubleshooting-log.md`. Log device work in that device's file. The log is the homelab's **learning diary** — not just a problem log. It captures issues, fixes, successful projects, lessons learned, and configuration changes.

## When to log

Log an entry when ANY of these apply:

- A non-standard fix was applied to recover a service
- A new service was deployed or major config change happened
- A lesson was learned (what worked, what didn't, mistakes to avoid)
- A network, security, or infrastructure modification was made

**Governance override:** `homelab-governance.mdc` §5 requires **always** appending to `docs/reference/troubleshooting-log.md` after **resolving** an incident or **applying** a production-affecting change on this server (tunnel, Caddy, Docker stack, deploys, etc.), with enough detail for future reference — unless the user **explicitly** asked not to log. When that rule applies, treat logging as **part of closing the task**, not optional.

## When NOT to log

Skip **only** when:

- The user **explicitly** asked not to log (per governance §5 exception), or
- The work is **purely** cosmetic documentation elsewhere with **zero** runtime impact and no troubleshooting story (e.g. typo in an unrelated doc).

If unsure whether it counts as production-affecting or incident resolution, **log it** — a short entry is better than no trail.

## Entry template

Add the entry at the **top** of the log (newest first, right under the intro). Recent entries use this compact shape; read the top two and match them:

```markdown
## [YYYY-MM-DD] Descriptive title

**Symptom / Goal:** what was wrong or wanted.

**Change (live):** what changed on the host, with live paths.

**Change (repo = live via /opt/homelab):** repo files touched (`scripts/` is live).

**Verification:** commands run and their output.

**Gotchas:** anything non-obvious (optional).

**Outcome / Still open:** fixed, mitigated, or what's left.
```

## Authoring rules

1. **Title**: descriptive, dated. Example: `## [2026-05-01] Fixed Caddy 502 on Jellyfin after gzip regression`
2. **Be detailed**: write so future-you (6 months from now) understands the full context.
3. **Include actual commands**: the command history is the most valuable part. Paste real `docker logs`, `curl`, `systemctl` invocations.
4. **Document mistakes too**: failed approaches are learning data. Note what you tried that didn't work and why.
5. **Cross-reference**: link to related prior entries, related runbooks (`MONITORING_AND_RECOVERY.md`, `CLOUDFLARE_MONITORING.md`), or commits.
6. **Append-only**: new entries go at the top. Never edit or delete existing entries.
7. **Public repo**: no passwords, tokens, webhook or ntfy URLs.

## Workflow

```
- [ ] 1. Confirm with user the fix is worth logging (skip if trivial)
- [ ] 2. Read the last 1-2 entries to match tone/depth
- [ ] 3. Draft entry using the template above
- [ ] 4. Add it at the top of the device's log (do not modify existing entries)
- [ ] 5. Show the user the new block for confirmation
- [ ] 6. Blog-worthy story? Follow CLAUDE.md habit 7 (docs/blog-ideas.md)
```

## Reference

For the full guidelines authored by the user, see [troubleshooting-log-guidelines.md](../../../docs/reference/troubleshooting-log-guidelines.md).
