---
name: prepare-pull-request
description: Commit and publish work in the homelab repo safely - small atomic commits while working, a secret scan, then either a direct push (lemongrab) or a pull request (Pi, Terra, dev machine), plus the deploy step after merge. Use when the user says "commit this", "open a PR", "prepare a pull request", "push", "ready to merge", "sync with main", "scan for secrets", "check the commit for credentials", or "before I push".
---

# Commit and Publish (prepare-pull-request)

Small commits while you work, one scan before anything leaves the machine, and a
publish step that respects where you are. On lemongrab a push is cheap but a
`checkout` or `pull` is a deploy (see `CLAUDE.md`).

## 1. Where am I? (publication mode)

Run `hostname` first. The machine decides how work is published:

| Machine | Mode | Why |
|---|---|---|
| `lemongrab` | **Direct**: commit on `main`, push `main` at the end of the task | The working tree is live; the change already happened. The commit records it. Switching branches mid-task would revert live scripts. |
| `pihole`, `cricket` (Terra), dev machine | **PR**: `feature/<yyyy-mm-dd>-<short-name>` branch, PR into `main` | Their checkout is not production (except Unbound on the Pi), so review costs nothing. |

The user can ask for a PR from lemongrab too: `git switch -c feature/<name>` is
safe (no files change). Never `git checkout` an *existing* other branch there.

`develop` is not used (12 commits behind `main` as of 2026-10-17). Don't target it.

## 2. Atomic commits while working

Commit after each step that works, not once at the end. The goal: anyone reading
`git log` later can see what changed, in what order, and revert one step alone.

One commit is **one logical change**:
- One service, one fix, one doc update. Two unrelated fixes = two commits, even
  if you made them together.
- It passes pre-commit on its own and leaves nothing half-done (a script and the
  config it needs go together).
- A production change carries its troubleshooting-log entry **in the same
  commit**, so the log and the change can't drift apart.
- Pure moves/renames are their own commit, never mixed with edits.

Stage exactly that change: `git add <paths>` (or `git add -p` for a file with
two changes). Never `git add -A` blindly; check `git status` first.

**Message** (match the existing history):
```
<Area>: <what changed, as an outcome>; log <yyyy-mm-dd>
                                              <- blank line
<optional body: live path vs repo path, why, anything non-obvious>
```
- Area is the device or service: `Pi:`, `Terra:`, `Caddy:`, `Immich:`, `B2 sync:`.
  lemongrab-wide work can skip it.
- The subject says the result, not the activity: "Pi-hole upstream to Unbound
  (was Google)", not "update compose".
- Add `; log <date>` when there is a troubleshooting-log entry, so the commit and
  the entry find each other.
- Say "live" vs "repo only" in the body when it isn't obvious.

Don't squash or reorder commits that are already pushed. Before pushing you may
fold a typo fix into its parent (`git commit --fixup <sha>` then
`GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash origin/main`), but keeping
small commits is the point; don't merge them into one big one.

## 3. Before publishing: sync

```bash
git fetch origin
git log --oneline HEAD..origin/main    # commits on main you don't have
```

- Nothing new on `main`: continue.
- New commits, nothing pushed yet: `git rebase origin/main`.
- New commits, branch already pushed: `git merge origin/main` locally.
- **Never** open a "sync" PR from `main` into a feature branch. Those back-merge
  PRs (#105 to #111) added noise and auto-titles ("Merge pull request #109...")
  that say nothing.
- On lemongrab, `git pull --ff-only` is a deploy: fine when you mean it, then
  run `grep -c SQLITE_TAR /opt/homelab/scripts/backup-engine.sh` (expect 1).

Conflicts: resolve only inside the files of this change (surgical rule). If a
conflict shows work is needed elsewhere, STOP and ask.

## 4. Scan (mandatory before any push)

The repo is **public**. `.gitignore` covers `.env`, keys, `health_webhook_url`,
`ntfy_topic_url`, `healthcheck_ping_url` and cloudflared JSON, but secrets still
leak inline.

```bash
gitleaks git --no-banner --log-opts="origin/main..HEAD"     # installed, v8.30
pre-commit run --from-ref origin/main --to-ref HEAD         # private keys, large files, yaml, shellcheck
```

Then this regex pass for homelab-specific leaks gitleaks may miss:

```bash
git diff origin/main..HEAD | rg -n -e \
    'ntfy\.sh/[A-Za-z0-9_-]{6,}' \
    -e 'hc-ping\.com/[0-9a-f-]{20,}' \
    -e 'PrivateKey\s*=' \
    -e '(?i)(api[_-]?key|secret|passwd|password|token|admin_token)\s*[:=]\s*["'"'"']?[A-Za-z0-9_/+=$.-]{16,}' \
    -e '(?i)bearer\s+[A-Za-z0-9_/+=.-]{20,}' \
    -e '-----BEGIN [A-Z ]*PRIVATE KEY-----'
git diff --name-only origin/main..HEAD | rg -i '\.env$|credentials|\.key$|\.pem$|\.bak-'
```

**Any hit:** stop and show the line. If it is real:
1. Remove it from the commit (rewrite the unpushed commit; if already pushed, it is public).
2. **Rotate the secret.** Assume it is compromised, even if it was only pushed for a minute.
3. Re-scan.

Placeholders (`changeme`, `<token>`, templates) can be acknowledged and skipped.

## 5. Publish

**Direct (lemongrab):**
```bash
git log --oneline origin/main..HEAD   # show the user what goes out
git push origin main                  # only after the user OKs the push
```

**PR (other machines):**
```bash
git push -u origin HEAD
gh pr create --base main --title "<outcome, same style as a commit subject>" --body "$(cat <<'EOF'
## What changed
- <one line per commit or group of commits>

## Live vs repo
- <what was already changed live, on which machine; what is repo only>

## Log entries
- <device> log <yyyy-mm-dd>: <title>

## After merge (deploy)
- <exact steps, see below, or "none: docs only">

## Verification
- [ ] gitleaks + regex scan clean
- [ ] pre-commit passes
- [ ] <verify-services.sh / curl / test script as relevant>
EOF
)"
```
Show the command first; run `gh pr create` only after the user confirms.

**Merge with "Create a merge commit" or "Rebase and merge", never "Squash".**
Squash turns the small commits back into one big one.

## 6. After merge: deploy where needed

| Changed | Do after merge |
|---|---|
| `scripts/`, `docker/caddy/` (lemongrab reads them from the checkout) | On lemongrab: `git fetch && git pull --ff-only` on `main`, then the `SQLITE_TAR` check; for Caddy, validate and restart |
| `pihole/docker/unbound/` | On the Pi: `git switch main && git pull --ff-only`, then `cd pihole/docker/unbound && docker compose up -d` |
| Live paths outside the repo | Nothing: they were changed live first; the PR only records them |
| Docs only | Nothing |

On lemongrab, after a PR you opened from there merges, move back with one
command so the tree is never on stale `main`: `git fetch && git switch -C main origin/main`.
Then delete the merged branch (`git branch -d feature/<name>`).

## Hard rules

- Never `git push --force` to `main`. On a feature branch only with the user's OK, and `--force-with-lease`.
- Never `--no-verify` unless the user asks.
- Never commit a secret "to fix later". Stop and surface it.
- Never `git checkout`/`switch` to an existing older branch on lemongrab or on the Pi.
- Stay surgical: no reformatting or lint fixes outside the change.
