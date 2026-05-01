---
name: prepare-pull-request
description: Prepare a pull request for the homelab repo — sync the working branch with origin/main, scan staged or committed changes for secrets (API keys, passwords, tokens, private keys, webhook URLs), run hygiene checks, and draft the gh pr create command. Use when the user says "open a PR", "prepare a pull request", "ready to merge", "sync with main", "scan for secrets", "check the commit for credentials", or "before I push".
---

# Prepare Pull Request

Two-phase pre-PR workflow: (1) bring the branch up to date with `origin/main`, (2) scan the diff for secrets and other hygiene issues. Refuse to draft the PR command until both phases pass.

## Workflow

```
- [ ] 1. Read current branch + status; confirm not on main
- [ ] 2. Fetch origin and check how main has moved
- [ ] 3. Sync strategy (rebase vs merge) — ask if ambiguous
- [ ] 4. Resolve any conflicts surgically (don't touch unrelated services)
- [ ] 5. Run secret scan against the diff
- [ ] 6. Run hygiene checks (large files, .env, gitignored leaks, debug prints)
- [ ] 7. Run pre-commit if configured
- [ ] 8. Summarize the changes
- [ ] 9. Draft gh pr create command for user to run
```

## 1. Branch state

```bash
git status
git branch --show-current
git log --oneline origin/main..HEAD
```

If currently on `main`: stop and ask the user whether they want to (a) push directly to `main` (homelab norm for hotfixes — but require explicit confirmation), or (b) create a feature branch.

## 2. Check for upstream movement

```bash
git fetch origin
git log --oneline HEAD..origin/main          # commits on main not in HEAD
git log --oneline origin/main..HEAD          # commits on HEAD not on main
```

If `HEAD..origin/main` is empty, the branch is already up to date — skip to step 5.

## 3. Sync strategy

Ask the user once if not specified:

- **Rebase** (preferred for clean linear history): `git rebase origin/main`
- **Merge** (preserves merge commits): `git merge origin/main`

Default: rebase. Switch to merge if the branch is shared with others or has been pushed already with rebase-incompatible history.

NEVER `git push --force` to `main`. Force-push on a feature branch is acceptable only after explicit user confirmation, and prefer `--force-with-lease` over `--force`.

## 4. Conflict resolution (surgical rule)

Per the homelab governance rule: when resolving conflicts in a service-specific change, do NOT also touch unrelated services. If a conflict reveals that work elsewhere is required, STOP and ASK the user.

```bash
git status                                    # see conflicted files
# resolve each file
git add <file>
git rebase --continue   # or git merge --continue
```

## 5. Secret scan (mandatory before PR)

The homelab `.gitignore` already excludes `.env`, `*.key`, `*.pem`, `credentials.json`, `health_webhook_url`, and cloudflared JSON files. The scan still runs because secrets can leak via:
- Hardcoded tokens in committed scripts or compose files
- Webhook URLs pasted inline
- New file types not yet covered by `.gitignore`

### Try real tools first (preferred)

Detect what's installed and use the best available:

```bash
if command -v gitleaks &>/dev/null; then
    gitleaks detect --no-git --staged --verbose
    gitleaks protect --staged --verbose      # alternate
elif command -v trufflehog &>/dev/null; then
    trufflehog git file://. --since-commit origin/main --only-verified
elif command -v detect-secrets &>/dev/null; then
    git diff origin/main..HEAD | detect-secrets scan --string
fi
```

If none are installed and the user wants persistent scanning, suggest installing one of them under `/home` (per the workspace storage-preference rule) — for example `pipx install detect-secrets` or download `gitleaks` to `~/.local/bin/`. Do NOT install without confirmation.

### Regex fallback (always run this)

Even when a real scanner is present, run the curated `rg` patterns below against the diff as a belt-and-suspenders check. Include this exact command:

```bash
git diff origin/main..HEAD | rg -n --color=always -e \
    'AKIA[0-9A-Z]{16}' \
    -e 'gh[ps]_[A-Za-z0-9]{36}' \
    -e 'glpat-[A-Za-z0-9_-]{20}' \
    -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
    -e 'sk-[A-Za-z0-9]{20,}' \
    -e '-----BEGIN ((RSA|EC|OPENSSH|DSA|PGP) )?PRIVATE KEY-----' \
    -e 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]+' \
    -e 'https://hooks\.slack\.com/services/[A-Z0-9/]+' \
    -e 'https://discord(app)?\.com/api/webhooks/[0-9]+/[A-Za-z0-9_-]+' \
    -e '(?i)(api[_-]?key|apikey|access[_-]?key|secret|passwd|password|token)\s*[:=]\s*["'"'"']?[A-Za-z0-9_/+=-]{16,}["'"'"']?' \
    -e '(?i)bearer\s+[A-Za-z0-9_/+=.-]{20,}'
```

What each pattern catches:

| Pattern | Catches |
|---|---|
| `AKIA…` | AWS access key ID |
| `ghp_/ghs_` | GitHub personal/server tokens |
| `glpat-…` | GitLab personal access tokens |
| `xox[baprs]-…` | Slack tokens |
| `sk-…` | OpenAI / Stripe-style API keys |
| `-----BEGIN … PRIVATE KEY-----` | RSA, EC, OpenSSH, DSA, PGP private keys |
| `eyJ…` | JWTs (header.payload.signature) |
| Slack/Discord webhook URLs | Webhook secrets |
| Generic `key=value` with 16+ char value | Catch-all for `API_KEY=…`, `password=…`, `token=…` |
| `bearer …` | Authorization headers |

**If ANY pattern matches**: stop. Show the user the line(s), confirm whether it's a real secret or a false positive. If real:
1. Remove from the diff (`git restore --staged`, edit the file, re-add)
2. Add the file to `.gitignore` if appropriate
3. **Rotate the secret** — assume it's compromised
4. Re-scan before proceeding

False positives (e.g. `gokapi/config.json.template` placeholder) can be acknowledged and the scan re-run.

## 6. Hygiene checks

```bash
# Files larger than 1 MB in the diff (likely shouldn't be in git)
git diff --stat origin/main..HEAD | awk '$NF ~ /M$/ || $(NF-1) > 1000'

# .env or credential files accidentally added
git diff --name-only origin/main..HEAD | rg -i '\.env|credentials|secret|\.key$|\.pem$|health_webhook_url'

# Leftover debug/dev artifacts
git diff origin/main..HEAD | rg -n --color=always -e \
    'console\.log' \
    -e '\bbreakpoint\(\)' \
    -e '\bipdb\b' \
    -e '\bpdb\.set_trace' \
    -e 'TODO.*FIXME|FIXME.*XXX'
```

Anything that hits should be discussed with the user before continuing.

## 7. Run pre-commit (if available)

The repo has `.pre-commit-config.yaml` with `detect-private-key`, `check-added-large-files`, `yamllint`, `shellcheck`, etc.

```bash
if command -v pre-commit &>/dev/null; then
    pre-commit run --from-ref origin/main --to-ref HEAD
fi
```

If `pre-commit` is not installed, mention it but don't block.

## 8. Summarize the changes

```bash
git log --oneline origin/main..HEAD
git diff --stat origin/main..HEAD
```

Draft a concise summary: services touched, type of change (feat/fix/docs/refactor), risk level. Cross-check against the surgical-rule files (Caddyfile globals, `~/.cloudflared/config.yml`, `enhanced-health-check.sh`, `systemd/*`) — if any of those are touched, flag it loudly so the user can confirm intent.

## 9. Draft the gh pr create command

```bash
git push -u origin HEAD                      # only if user confirmed

gh pr create --title "<concise title>" --body "$(cat <<'EOF'
## Summary
<1-3 bullets on what changed and why>

## Services touched
- <service>: <change>

## Verification
- [ ] scripts/verify-services.sh green
- [ ] curl checks for any new/changed subdomain
- [ ] No secrets in diff (gitleaks/regex scan clean)

## Notes
<anything reviewer should know>
EOF
)"
```

Show the command to the user; do NOT execute `gh pr create` without explicit confirmation.

## Hard rules

- NEVER `git push --force` to `main`. Always `--force-with-lease` and only on feature branches with explicit user OK.
- NEVER bypass pre-commit hooks (`--no-verify`) unless the user explicitly asks for it.
- NEVER auto-commit secrets you found "to fix later". Halt and surface them.
- If a secret is found, **the secret is compromised** — instruct the user to rotate it, not just remove it from the diff.
- Stay surgical: don't reformat unrelated files, don't fix lints in code outside the diff.

## Reference

- Repo `.gitignore` already excludes the standard sensitive files
- Pre-commit config: `.pre-commit-config.yaml`
- Surgical rule and read-only files: see governance rule (`homelab-governance.mdc`)
