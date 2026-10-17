---
name: blog-review
description: Review the blog candidates that the blog-capture rule (.cursor/rules/blog-capture.mdc) wrote during homelab work, and decide one at a time whether each is worth a post on gmojsoski.com. Use when the user says "review my blog ideas", "blog review", "go through the blog candidates", or as part of the weekly review. For each candidate in .cursor/blog/pending/ shows it and asks approve, reject, merge or skip; approved ones go to approved/ with an outline, rejected ones to rejected/ with the user's reason in decisions.md. Also marks approved posts as published once written. Never writes the post itself or touches the portfolio repo unless asked.
---

# Blog Review

Works through `.cursor/blog/pending/`, one candidate at a time, oldest first, and moves each
where the owner decides. Same shape as `lesson-review`.

## Workflow

1. **List the queue.** Read every file in `.cursor/blog/pending/` (ignore `.gitkeep`). One line
   each: date, slug, title. Point out candidates that overlap (same incident, or the same idea
   from two angles) so the owner can merge them.

2. **One at a time.** Show the full candidate, then give a short verdict against the bar below,
   so the owner gets an opinion, not just a form. Ask: **approve, reject, merge, or skip**.

   The bar (from the stiki "fresh-eyes reader test"):
   - A stranger with no knowledge of this homelab learns something they can use on their own.
   - There's a real story: what looked true, what was actually true, how it was found.
   - The evidence exists: the log entries have the commands, numbers or output to show.
   - It can be told without anything from **Public check** that must stay private.

3. **Approve:**
   - Fill in **Outline** (4 to 6 headings, following the story beats) and **Effort**
     (`TIL`, about 300 words, or `post`, 1000+).
   - Ask for a priority (`next`, `soon`, `someday`) and set it.
   - `git mv` to `.cursor/blog/approved/`; add a row at the top of `.cursor/blog/decisions.md`.

4. **Reject:** ask for a short reason (don't guess one). Add a row to `decisions.md`, `git mv`
   to `rejected/`. The reason stops it coming back without new evidence.

5. **Merge:** fold the weaker candidate's evidence and angle into the stronger one, `git rm`
   the weaker file, log one "Merged" row naming both.

6. **Skip:** leave it pending.

7. **Approved queue.** After pending is clear, list `approved/` by priority. For any the owner
   says is now live, add the URL under **Published**, `git mv` to `published/`, log it.

8. **Commit** the moves as one commit: `Blog review <date>: N approved, N rejected`.

## Writing a post (only when asked)

Draft from the candidate's linked log entries. Facts come from the logs, not from memory; mark
anything not in a log as unverified and ask. Put a short note under the title that it was
written with AI help and reviewed by the author. Run the **Public check** again on the draft.
The post goes to the `portfolio_v2` repo, not here.

## Output style

Plain English, no em dashes, one candidate per message, never "approve all".
