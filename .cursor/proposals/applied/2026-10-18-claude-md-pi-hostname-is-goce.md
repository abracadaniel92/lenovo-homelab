**Proposed change:** `CLAUDE.md`, section "FIRST: figure out which machine you're on", the Pi
bullet. It says "**On the Pi (`pihole`):**" but the Pi's `hostname` prints `goce`. Change it to
"**On the Pi (hostname `goce`, the Pi-hole box):**" so the `hostname` check actually matches.

**Why now:** A session on the Pi ran `hostname`, got `goce`, matched none of the listed
machines and fell back to repo-only. The owner had to say "goce=pihole".

**Evidence:** 2026-10-18: `hostname` on the Pi returned `goce`. The weekly review skipped parts
3 to 5 as "unknown machine" until the owner corrected it. Lemongrab (`lemongrab`) and the Terra
(`cricket`) bullets already match their hostnames.

**Scope:** `CLAUDE.md`

**Boundaries:** Only the hostname in the Pi bullet. Does not rename the `pihole/` folder or
touch the Pi's rules.
