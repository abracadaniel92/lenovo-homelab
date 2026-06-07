#!/bin/bash
# Install systemd timer for weekly MCP knowledge refresh (Sunday 03:00).
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with: sudo bash $0"
  exit 1
fi

REPO="$(cd "$(dirname "$0")/.." && pwd)"
MCP_SERVER="$(cd "$REPO/../mcp_server" && pwd)"
chmod +x "$MCP_SERVER/scripts/weekly-knowledge-refresh.sh"

cp "$REPO/systemd/knowledge-mcp-weekly-refresh.service" /etc/systemd/system/
cp "$REPO/systemd/knowledge-mcp-weekly-refresh.timer" /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now knowledge-mcp-weekly-refresh.timer

echo "Installed. Status:"
systemctl list-timers knowledge-mcp-weekly-refresh.timer --no-pager
echo ""
echo "Logs: /home/goce/Desktop/Cursor projects/mcp_server/data/weekly-refresh.log"
echo "Manual run: bash .../mcp_server/scripts/weekly-knowledge-refresh.sh"
