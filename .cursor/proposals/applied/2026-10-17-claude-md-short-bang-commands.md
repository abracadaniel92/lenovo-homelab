**Proposed change:** `CLAUDE.md`, "Commands (on the server)" section. Add: "The owner often works from a phone over Termius (SSH), where pasted long
lines wrap and each wrapped line runs as its own command. When the user must run a command
themselves (`! <cmd>`), keep it to one short line with no `&&` chain past two
steps, or put the steps in a script under the scratchpad and give `! bash <script>`. On a desktop terminal this doesn't happen, but you can't tell which one the user is on, so
always keep it short."

**Why now:** A long `!` command broke into separate commands twice in one session.

**Evidence:** 2026-10-17. A merge-and-push one-liner was pasted back wrapped over three or four
lines: first as plain text (nothing ran), then as `<bash-input>` where `merge` ran alone,
`--no-edit` failed as a command, the push never ran, and `backup-engine.sh` ran with no
arguments (it only printed usage). The agent then pushed itself. The owner confirmed it only happens on the phone via
Termius, not on a desktop terminal.

**Scope:** `CLAUDE.md`

**Boundaries:** One note. Does not change when the agent asks the user to run commands.
