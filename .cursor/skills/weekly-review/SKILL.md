---
name: weekly-review
description: The owner's weekly homelab review in one pass - lesson proposals, blog candidates, open items left in the troubleshooting logs, decisions whose reverse condition may now be true, and a quick drift check. Use when the user says "weekly review", "let's do the weekly", or "what's piled up". Runs lesson-review and blog-review, then sweeps the logs. Never closes an item or applies a change without the owner's say-so.
---

# Weekly Review

One entry point for the weekly habit. Adapted from the stiki "weekly sweep for stale
knowledge, triggered reverse conditions and drift". Do the parts in order; the owner can stop
after any part.

Start by saying which machine you're on (`hostname`). The full review needs lemongrab (the
drift checks read live state); elsewhere do parts 1 and 2 and say parts 3 to 5 were skipped.

## 1. Lessons

Follow the `lesson-review` skill. If `.cursor/proposals/pending/` is empty, say so in one line
and move on.

## 2. Blog candidates

Follow the `blog-review` skill. If `.cursor/blog/pending/` is empty, list `approved/` with the
`next` priority ones first, so a post actually gets written.

## 3. Open items

Each log entry can end with "Still open", "Next steps", "Pending", "Not done" or "Open". They
pile up and nobody comes back to them.

```bash
for f in docs/reference/troubleshooting-log.md pihole/troubleshooting-log.md terra/troubleshooting-log.md; do
  rg -n -i '^\*\*(still open|next steps?|pending|not done|open)\b' "$f"
done
```

Read only entries from the last ~6 weeks, plus anything an earlier weekly review carried over.
For each item:
- **Check reality first** where you can (does the `.bak` file still exist? is the timer
  enabled? `docker ps`?). Report what you found, not just what the log says.
- Ask the owner: **done, still open, or drop**.

Then add ONE new entry at the top of the lemongrab log (append-only: never edit the old
entries):

```markdown
## [YYYY-MM-DD] Weekly review: open items

**Closed:** <item> (from log <date>): <how it was verified>.
**Dropped:** <item> (from log <date>): <owner's reason>.
**Carried over:** <item> (from log <date>), open since <date>.
```

Next week, read this entry first; carried-over items are the list to start from. Device items
(Pi, Terra) are listed here too, by device, so there is one place to look.

## 4. Reverse conditions

Decisions to NOT do something (no host firewall, Jellyfin left on 10.11, `develop` retired)
carry a `**Reverse if:**` line in their log entry, stating what would reopen them.

```bash
rg -n '^\*\*Reverse if:\*\*' docs/reference/troubleshooting-log.md pihole/troubleshooting-log.md terra/troubleshooting-log.md
```

For each, check whether the condition is now true (e.g. "Jellyfin 12 has been out 3 months
and plugins support it"). Report only the ones that have triggered or that you can't check;
the owner decides whether to reopen.

## 5. Drift (quick)

```bash
docker ps -q | wc -l                                   # vs the README badge
for d in .cursor/skills/*/; do printf '%s %s\n' "$(git log -1 --format=%cs -- "$d")" "$d"; done | sort
git log --oneline origin/main..HEAD | wc -l            # unpushed commits
```

Report: a container count that doesn't match the README, skills unchanged for 3+ months while
their area had log activity, and unpushed commits. Suggest fixes; don't make them.

## 6. Wrap up

One short summary: lessons applied/rejected, blog candidates approved/rejected, open items
closed/carried, reverse conditions triggered, drift found. Commit the review's own changes
(moves, decisions rows, the log entry) as one commit, `Weekly review <date>`, and push only if
the owner says so.

## Output style

Plain English, no em dashes, one decision at a time, never "approve all".
