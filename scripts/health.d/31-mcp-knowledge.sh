#!/bin/bash
# 31-mcp-knowledge.sh: MCP Knowledge Server (knowledge-mcp on host port 8001)

MCP_COMPOSE_DIR="/home/goce/Desktop/Cursor projects/mcp_server"
MCP_SSE_URL="http://127.0.0.1:8001/sse"

check_mcp_sse() {
    local first_line
    first_line=$(curl -sN --max-time 4 "$MCP_SSE_URL" 2>/dev/null | head -1)
    echo "$first_line" | grep -q 'event: endpoint'
}

if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'knowledge-mcp'; then
    log "WARNING: knowledge-mcp container not running. Starting..."
    if [ -d "$MCP_COMPOSE_DIR" ]; then
        (cd "$MCP_COMPOSE_DIR" && docker compose up -d) || true
        sleep 5
    else
        log "ERROR: MCP compose dir missing: $MCP_COMPOSE_DIR"
    fi
fi

if ! check_mcp_sse; then
    log "WARNING: MCP Knowledge Server not responding on port 8001. Restarting..."
    if [ -d "$MCP_COMPOSE_DIR" ]; then
        (cd "$MCP_COMPOSE_DIR" && docker compose restart knowledge-mcp) || true
        sleep 5
        if check_mcp_sse; then
            log "INFO: MCP Knowledge Server recovered after restart."
        else
            log "ERROR: MCP Knowledge Server still down after restart."
        fi
    fi
fi
