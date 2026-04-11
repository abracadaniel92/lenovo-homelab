# Security policy

This document describes how we handle security for **lenovo-homelab** (configuration, Docker Compose, Caddy, scripts, and related automation). It applies to this repository and the infrastructure it describes.

## Scope

**In scope for reports**

- Misconfigurations or weaknesses in **this repository** (e.g. secrets in commits, unsafe defaults in compose/Caddy/scripts, broken auth boundaries in configs we control).
- Issues that could realistically affect **confidentiality, integrity, or availability** of services deployed from this repo when operated as documented.

**Out of scope**

- Physical access, theft of hardware, or compromise of accounts outside this repo’s control.
- Purely upstream issues (e.g. CVEs in upstream Docker images or apps) unless you can tie them to **how we configure or deploy** them here—those reports usually belong to the upstream project.
- Denial-of-service against a personal homelab **without** a clear, reproducible link to this repo’s configuration.
- Social engineering or spam.

If you are unsure, report anyway; we will triage.

## Supported versions

This is **rolling infrastructure-as-code**: only the **`main`** branch is maintained. Security-relevant fixes land on `main`. Older branches or forks are not supported unless explicitly stated.

| Branch / state   | Security fixes |
| ---------------- | -------------- |
| `main`           | Yes, best effort |
| Other branches   | No guarantee   |
| Archived snapshots | Not supported |

## How to report a vulnerability

**Preferred (GitHub)**  

If you have a GitHub account and the issue is sensitive:

1. Open a **private vulnerability report** for this repository (**Security** → **Advisories** → **Report a vulnerability**), or use **GitHub Security Advisories** if available for the repo.

This keeps details off public issues and gives a structured thread.

**Email**  

You may also email: **contact@gmojsoski.com** with subject line starting with `[SECURITY] lenovo-homelab`.

**What to include**

- Description of the issue and why it matters.
- Affected paths, configs, or services (e.g. `docker/<service>/`, `docker/caddy/…`).
- Steps to reproduce (commands, minimal proof-of-concept if safe).
- Whether you believe it is already exploitable in the wild (if known).

Do **not** send passwords, session tokens, or live secrets. Use redacted examples.

## What to expect after you report

- **Acknowledgement**: We aim to respond within **7 days** for valid reports (personal homelab; not a commercial SLA).
- **Assessment**: We will confirm whether we agree it is in scope and whether we plan a fix.
- **Fix & disclosure**: We prefer **coordinated disclosure**—we work on a fix before public discussion when reasonable. For issues fixed in git, the commit message or advisory may reference the class of issue without crediting you unless you ask to be named.
- **Declined reports**: We will explain briefly if we close as out of scope, not reproducible, or accepted risk for this environment.

## Secure development practices (maintainers)

- Prefer **no secrets in git**; use environment files or secret managers excluded by `.gitignore`, and rotate if exposed.
- After network or ingress changes, run **`./scripts/verify-services.sh`** and follow **SERVICE_ADDITION_CHECKLIST.md** for new services.
- Keep **Cloudflare tunnel** and **Caddy** configs aligned with documented rules (e.g. tunnel origin `http://localhost:8080` as in your deployment standards).

## Contact

For non-security questions, use normal repository **Issues** or your usual maintainer channels. Use this policy and private reporting only for **security-sensitive** matters.
