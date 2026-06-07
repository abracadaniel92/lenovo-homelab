# MCP Knowledge Server (LAN only)

Private MCP server for Cursor: local search over exported work items, wiki pages, and documents. **Not exposed to the internet** — LAN/VPN only, no auth layer.

## Quick reference

| Item | Value |
|------|--------|
| **Container** | `knowledge-mcp` |
| **Host port** | **8001** (container internal 8000) |
| **Why not 8000?** | Port 8000 is used by another service on this host |
| **SSE URL (LAN)** | `http://192.168.1.97:8001/sse` |
| **SSE URL (on server)** | `http://127.0.0.1:8001/sse` |
| **Compose / code** | `/home/goce/Desktop/Cursor projects/mcp_server` |
| **Database** | `mcp_server/data/knowledge.db` |
| **Restart policy** | `unless-stopped` |

Browser test: `/sse` should return `event: endpoint` — server is up. Cursor handles the rest.

## Operations

```bash
cd "/home/goce/Desktop/Cursor projects/mcp_server"
./scripts/check-service.sh
docker compose up -d --build
docker compose restart knowledge-mcp
./ingest_all.sh && docker compose restart knowledge-mcp
```

### Weekly auto-refresh (Sunday 03:00)

- **Script:** `mcp_server/scripts/weekly-knowledge-refresh.sh` — Jira API export → CSV → full ingest → restart container.
- **Log:** `mcp_server/data/weekly-refresh.log`
- **Jira ingest uses CSV** (full descriptions, no Excel cell limit).
- **Install timer (once):**
  ```bash
  sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/deploy-knowledge-mcp-weekly-refresh.sh"
  ```
- **Manual run:** `bash .../mcp_server/scripts/weekly-knowledge-refresh.sh`

### Confirm ports

```bash
ss -tln | grep -E ':8000|:8001'
docker ps --format '{{.Names}}\t{{.Ports}}' | grep -E '8000|8001'
```

Only `knowledge-mcp` should bind host **8001**.

## Cursor

- `mcp_server/.cursor/mcp.json` or merge `mcp-config.json`
- Enable **homelab-knowledge** under **Settings → MCP**
- Tools: `search_issues`, `get_issue`, `get_epic_context`, `search_wiki_pages`, `get_wiki_page`, `search_documents`, `get_document_by_id`

## Claude Code CLI (Termius / SSH)

Use the same index from the `claude` CLI when SSH'd into the server (e.g. via Termius over no-ip). The MCP listens on localhost only, so this works **on the box** — no internet exposure.

- **Authenticate Claude Code first (one-time, headless box).** The normal browser `/login` fails over SSH (no localhost callback → *"invalid OAuth request"*). Use the paste-code flow instead:
  ```bash
  claude setup-token          # subscription; open URL in any browser, paste code back
  # or, API key (pay-per-use): echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.bashrc
  ```
  This is Claude Code's own Anthropic login — separate from the MCP, but required before the MCP tools work.
- **Register the MCP once (user scope → available from any directory):**
  ```bash
  claude mcp add --scope user --transport sse homelab-knowledge http://127.0.0.1:8001/sse
  ```
  Writes to `~/.claude.json` for user `goce`. SSH in as `goce` for it to apply.
- **Verify:** `claude mcp list` → `homelab-knowledge: ... (SSE) - ✓ Connected`
- **Use:** run `claude`, or one-shot:
  ```bash
  claude -p "search the knowledge base for the cyber resilience act support period"
  ```
- **If disconnected:** the container is down — `cd "/home/goce/Desktop/Cursor projects/mcp_server" && docker compose up -d`.

Same 7 tools as Cursor (`search_issues`, `get_issue`, `get_epic_context`, `search_wiki_pages`, `get_wiki_page`, `search_documents`, `get_document_by_id`).

### Search behavior (chunks + semantic)

- **Issues**: one row per ticket; search uses full `search_text` (includes description).
- **Wiki + documents**: chunked sections (~1.8 KB); search returns matching sections.
- **Hybrid search**: FTS5 keywords + local embeddings (multilingual MiniLM via FastEmbed). Helps when Jira/wiki use different wording. Built by `ingest_embeddings.py` (in `./ingest_all.sh`).
- **Disable semantic only**: set `SEMANTIC_SEARCH=0` on the container (keyword search still works).
- **No extra services** — model runs inside `knowledge-mcp`; cache under `mcp_server/data/embedding_cache` (~100MB).
- **Full page/doc**: `get_wiki_page` / `get_document_by_id`.

## Health monitoring

- Docker healthcheck on container port 8000
- `scripts/health.d/31-mcp-knowledge.sh`
- `enhanced-health-check.sh` probes SSE on **8001**

## Security

- **LAN/VPN only** — no Caddy/public hostname
- No API keys on the HTTP surface
