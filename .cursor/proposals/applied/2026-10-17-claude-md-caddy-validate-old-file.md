**Proposed change:** `CLAUDE.md`, "Commands (on the server)", the line
`docker exec caddy caddy validate --config /etc/caddy/Caddyfile  # before restarting Caddy`.
Add underneath: "After editing the root `Caddyfile` this validates the OLD file (single-file
bind mount keeps the old inode). Validate a copy instead:
`docker cp docker/caddy/Caddyfile caddy:/tmp/Caddyfile.new && docker exec caddy caddy validate --config /tmp/Caddyfile.new --adapter caddyfile`,
then `docker restart caddy`. Edits under `config.d/` (a directory mount) are seen normally."

**Why now:** The documented validate command gives a false pass for exactly the riskiest edit
(globals).

**Evidence:** 2026-10-08 lemongrab log, "Gotcha" in the Caddy access-logs entry: editing the
Caddyfile replaced the inode, so `caddy validate` / `caddy reload` silently tested the old
config. Compose confirms `./Caddyfile:/etc/caddy/Caddyfile` (file) and `./config.d` (dir).

**Scope:** `CLAUDE.md`

**Boundaries:** One note under the existing command. The same command also appears in
`add-homelab-service`, `troubleshoot-service-down` and the checklist; those only edit
`config.d/`, so they are fine and left alone.
