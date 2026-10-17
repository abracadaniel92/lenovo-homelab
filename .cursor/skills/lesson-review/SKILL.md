---
name: lesson-review
description: Review the lesson proposals that the lesson-capture rule (.cursor/rules/lesson-capture.mdc) wrote during day-to-day homelab work, and decide, one at a time, whether to apply them. Use when the user says "review my lessons", "go through the proposals", or similar; intended as a weekly habit. For each pending proposal in .cursor/proposals/pending/, shows it in full and asks approve, reject or skip; on approval makes the smallest matching edit to the named file, moves the proposal to applied/ and logs it in decisions.md; on rejection asks for a reason, logs it and moves the proposal to rejected/. Also offers a sweep for lessons repeating across skills and for stale skills. Never applies a proposal without the user's explicit approval of that one item.
---

# Lesson Review

Adapted from `abracadaniel92/product_manager_skills` (`lesson-review`).

Works through the proposals that built up in `.cursor/proposals/pending/`, one at a time, and
applies only the ones the user approves.

## When to use / not use

**Use when:**
- The user says "review my lessons," "let's go through the proposals," or similar.
- There's a pending proposal and the user wants to decide on it now.

**Do NOT use for:**
- Writing a new proposal: that happens under `.cursor/rules/lesson-capture.mdc` during normal
  work, not here.
- Homelab facts (an incident, a config change). If a "proposal" is really one of those, flag
  it and suggest logging it in the device's troubleshooting log instead of applying it.

## Workflow

1. **List what's pending.** Read every file in `.cursor/proposals/pending/` (ignore
   `.gitkeep`). If there are none, say so and still offer the sweep (step 5). List each
   proposal as one line: date, filename, and its **Proposed change**, so the user sees the
   whole queue first.

2. **One proposal at a time**, oldest first. No batch approvals. For each:
   - Show the full proposal (all five bullets).
   - Before asking, check the named file still says what the proposal quotes (files here
     change often). If it has already been fixed, say so and offer to reject as "already
     done".
   - Ask: approve, reject, or skip for now (leave it pending).

3. **On approval:**
   - Make the smallest edit to the file named in **Scope** that satisfies **Proposed change**,
     respecting **Boundaries**. A targeted edit, not a rewrite of the section.
   - Show the diff in the same message.
   - `git mv` the proposal from `pending/` to `applied/` (keep the filename).
   - Add one row at the top of the table in `.cursor/proposals/decisions.md`: date,
     "Applied", the file that changed, a one-line description.

4. **On rejection:**
   - Ask for a short reason. Don't guess one: the reason is what stops the idea from coming
     back without new evidence.
   - Add one row to `decisions.md`: date, "Rejected", the file it would have touched, the
     reason.
   - `git mv` the proposal to `rejected/`.

5. **Sweep.** After the queue is clear (or when asked), look across `applied/` and
   `decisions.md` and report suggestions, not changes:
   - **Repeated lessons.** The same point in two or more skills' proposals is a candidate for
     `CLAUDE.md` or `homelab-governance.mdc` instead of scattered `SKILL.md` notes.
   - **Stale skills.** `git log -1 --format=%cs -- .cursor/skills/<name>/SKILL.md` for each
     skill. One unchanged for months, while the troubleshooting logs show lots of activity in
     its area, deserves a read for drift.

6. **Commit** only if the user asks; mention that nothing here is live code.

## Output style

- Plain prose and short bullets; no tables for the walkthrough.
- Past tense once decided ("applied," "rejected").
- Plain English, no em dashes.
- Never offer "approve all".
