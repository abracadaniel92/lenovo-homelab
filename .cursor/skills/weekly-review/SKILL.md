---
name: weekly-review
description: The owner's weekly homelab review, run once per machine (lemongrab, the Pi, the Terra) - lesson proposals, blog candidates, open items left in THIS machine's troubleshooting log, decisions whose reverse condition may now be true, and a quick drift check against this machine's live state. Use when the user says "weekly review", "let's do the weekly", or "what's piled up". Runs lesson-review and blog-review, then sweeps this machine's log. Never closes an item or applies a change without the owner's say-so.
---

# Weekly Review

One entry point for the weekly habit, run **once on each machine**. Adapted from the stiki
"weekly sweep for stale knowledge, triggered reverse conditions and drift". Do the parts in
order; the owner can stop after any part.

## 0. Which machine

Run `hostname` and say which machine you're on. Parts 3 to 5 only touch that machine: its own
log, its own live state, its own entry.

| `hostname` | Machine | Log |
|---|---|---|
| `lemongrab` | lemongrab (main server) | `docs/reference/troubleshooting-log.md` |
| `goce` | the Pi | `pihole/troubleshooting-log.md` |
| `cricket` | the Terra | `terra/troubleshooting-log.md` |

Anything else (the Windows dev machine): do parts 1 and 2 only and say parts 3 to 5 were
skipped because they need the machine itself.

Then read the latest `Weekly review: open items` entry in this machine's log first: its
carried-over items are the list to start from.

## 1. Lessons

The queue is shared by all machines. Follow the `lesson-review` skill. If
`.cursor/proposals/pending/` is empty, say so in one line and move on.

## 2. Blog candidates

Also shared. Follow the `blog-review` skill. If `.cursor/blog/pending/` is empty, say so in one
line; list `approved/` (`next` priority first) only on the first machine reviewed this week, so
the owner doesn't see the same list three times.

## 3. Open items

Each log entry can end with "Still open", "Next steps", "Pending", "Not done" or "Open". They
pile up and nobody comes back to them. Search **this machine's log only** (`$LOG` from the
table):

```bash
rg -n -i '^\*\*(still open|next steps?|pending|not done|open)\b' "$LOG"
```

Read only entries from the last ~6 weeks, plus anything this machine's last weekly review
carried over. For each item:
- **Check reality first** (does the `.bak` file still exist? is the timer enabled?
  `docker ps`?). Report what you found, not just what the log says.
- An item about another machine: don't guess its state from here. Note it for that machine's
  review and move on.
- Ask the owner: **done, still open, or drop**.

Then add ONE new entry at the top of **this machine's** log (append-only: never edit the old
entries):

```markdown
## [YYYY-MM-DD] Weekly review: open items

**Closed:** <item> (from log <date>): <how it was verified>.
**Dropped:** <item> (from log <date>): <owner's reason>.
**Carried over:** <item> (from log <date>), open since <date>.
```

## 4. Reverse conditions

Decisions to NOT do something (no host firewall, Jellyfin left on 10.11, `develop` retired)
carry a `**Reverse if:**` line in their log entry, stating what would reopen them.

```bash
rg -n '^\*\*Reverse if:\*\*' "$LOG"
```

For each, check whether the condition is now true (e.g. "Jellyfin 12 has been out 3 months
and plugins support it"). Report only the ones that have triggered or that you can't check;
the owner decides whether to reopen.

## 5. Drift (quick)

On every machine:

```bash
git status -sb                                         # on main? local changes?
git log --oneline origin/main..HEAD | wc -l            # unpushed commits
```

Then the checks for this machine:

**lemongrab:**

```bash
docker ps -q | wc -l                                   # vs the README badge
for d in .cursor/skills/*/; do printf '%s %s\n' "$(git log -1 --format=%cs -- "$d")" "$d"; done | sort
```

Report a container count that doesn't match the README badge, and skills unchanged for 3+
months while their area had log activity. (Skills are shared, so only lemongrab does this.)

**The Pi (`goce`):**

```bash
docker ps --format '{{.Names}} {{.Status}}'           # pihole, unbound, uptime-kuma, all up
docker exec pihole pihole-FTL --config dns.upstreams   # must be ["127.0.0.1#5335"]
systemctl list-timers pi-backup.timer --no-pager       # last run last night
```

Also check that Unbound's `unbound.conf` mount points into this checkout
(`docker inspect unbound`), since a pull or branch switch can break it (`pihole/README.md`).

**The Terra (`cricket`):**

```bash
findmnt /mnt/offsite                                   # offsite drive mounted
systemctl is-active restic-rest-server                 # active
systemctl list-timers terra-watchdog.timer --no-pager  # running on schedule
```

Read only; never format or write into the offsite drive (`terra/README.md`).

Report what doesn't match. Suggest fixes; don't make them.

## 6. Wrap up

One short summary for this machine: lessons applied/rejected, blog candidates
approved/rejected, open items closed/carried, reverse conditions triggered, drift found, and
which machines still need their review this week. Commit the review's own changes (moves,
decisions rows, the log entry) as one commit, `Weekly review <date> (<machine>)`, and push only
if the owner says so.

## Output style

Plain English, no em dashes, one decision at a time, never "approve all".
