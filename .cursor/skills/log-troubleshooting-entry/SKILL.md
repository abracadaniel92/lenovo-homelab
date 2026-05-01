---
name: log-troubleshooting-entry
description: Append a properly-formatted entry to the homelab TROUBLESHOOTING_LOG.md following the project's entry template. Use when the user says "log this fix", "add a troubleshooting entry", "document this incident", "log to TROUBLESHOOTING_LOG", or after a non-standard fix has been applied and should be preserved as a learning record.
---

# Log Troubleshooting Entry

The `usefull files/TROUBLESHOOTING_LOG.md` is the homelab's **learning diary** — not just a problem log. It captures issues, fixes, successful projects, lessons learned, and configuration changes.

## When to log

Log an entry when ANY of these apply:

- A non-standard fix was applied to recover a service
- A new service was deployed or major config change happened
- A lesson was learned (what worked, what didn't, mistakes to avoid)
- A network, security, or infrastructure modification was made

## When NOT to log

Do NOT clutter the log with smooth, standard work:

- A clean container restart that just worked
- A standard new-service addition that followed the checklist with no surprises (the README update is enough)
- Trivial config tweaks with no learning value

## Entry template

Append to [TROUBLESHOOTING_LOG.md](../../../usefull%20files/TROUBLESHOOTING_LOG.md) using this exact structure:

```markdown
## [YYYY-MM-DD] Descriptive Title

**Date:** YYYY-MM-DD
**Action:** What was done
**Result:** Outcome of the action

### Root Cause / Background (if applicable)
- Why this was needed
- What led to this change

### Solution Applied / Implementation
1. Step-by-step what was done
2. Commands run
3. Files modified

### Verification
- How success was verified
- Test results

### Lessons Learned / Key Takeaways
- Important insights
- Best practices
- What to remember for next time

### Files Involved
- List of files created/modified
- Configuration locations

**Status**: Status description
```

## Authoring rules

1. **Title**: descriptive, dated. Example: `## [2026-05-01] Fixed Caddy 502 on Jellyfin after gzip regression`
2. **Be detailed**: write so future-you (6 months from now) understands the full context.
3. **Include actual commands**: the command history is the most valuable part. Paste real `docker logs`, `curl`, `systemctl` invocations.
4. **Document mistakes too**: failed approaches are learning data. Note what you tried that didn't work and why.
5. **Cross-reference**: link to related prior entries, related runbooks (`MONITORING_AND_RECOVERY.md`, `CLOUDFLARE_MONITORING.md`), or commits.
6. **Append-only**: add at the bottom or in chronological position. Never edit or delete existing entries.

## Workflow

```
- [ ] 1. Confirm with user the fix is worth logging (skip if trivial)
- [ ] 2. Read the last 1-2 entries to match tone/depth
- [ ] 3. Draft entry using the template above
- [ ] 4. Append to TROUBLESHOOTING_LOG.md (do not modify existing entries)
- [ ] 5. Show the user the appended block for confirmation
```

## Reference

For the full guidelines authored by the user, see [TROUBLESHOOTING_LOG_GUIDELINES.md](../../../usefull%20files/TROUBLESHOOTING_LOG_GUIDELINES.md).
