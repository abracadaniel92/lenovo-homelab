#!/bin/bash
###############################################################################
# GoatCounter Weekly Analytics Report Script
# Sends weekly analytics summary to Mattermost webhook (Slack-compatible format)
# Runs every Sunday at 10 AM via systemd timer
###############################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Prioritize analytics-specific webhook (Mattermost or legacy Slack)
[ -n "$ANALYTICS_MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$ANALYTICS_MATTERMOST_WEBHOOK_URL"
[ -n "$ANALYTICS_SLACK_WEBHOOK_URL" ] && [ -z "$MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$ANALYTICS_SLACK_WEBHOOK_URL"

# Default Mattermost webhook for analytics
MATTERMOST_WEBHOOK_URL="${MATTERMOST_WEBHOOK_URL:-https://mattermost.gmojsoski.com/hooks/jdyxig47nt8hig5se9cokndbey}"

GOATCOUNTER_DB="/mnt/ssd/docker-projects/goatcounter/goatcounter-data/goatcounter.sqlite3"

# Calculate date range (last 7 days)
END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d "7 days ago" +%Y-%m-%d)

# Check database exists
if [ ! -f "$GOATCOUNTER_DB" ]; then
    echo "ERROR: GoatCounter database not found at $GOATCOUNTER_DB"
    exit 1
fi

# Function to query database using sqlite3 docker image
query_db() {
    docker run --rm -v "$(dirname "$GOATCOUNTER_DB"):/db" nouchka/sqlite3:latest \
        "/db/$(basename "$GOATCOUNTER_DB")" "$1" 2>/dev/null
}

# Checkpoint WAL to ensure we see all data
query_db "PRAGMA wal_checkpoint;" > /dev/null 2>&1

# Get total pageviews from hit_counts (aggregated hourly data)
TOTAL_PAGEVIEWS=$(query_db "
    SELECT SUM(total)
    FROM hit_counts 
    WHERE hour >= datetime('now', '-7 days');
" | head -1)
TOTAL_PAGEVIEWS=${TOTAL_PAGEVIEWS:-0}

# Get top 5 pages using aggregated data
TOP_PAGES=$(query_db "
    SELECT p.path, SUM(hc.total) as visits 
    FROM hit_counts hc
    JOIN paths p ON hc.path_id = p.path_id 
    WHERE hc.hour >= datetime('now', '-7 days')
    GROUP BY p.path 
    ORDER BY visits DESC 
    LIMIT 5;
" | while IFS='|' read -r path visits; do
    [ -n "$path" ] && echo "  • ${path:-/} — ${visits} views"
done)

# Get top 5 referrers using aggregated data
TOP_REFERRERS=$(query_db "
    SELECT r.ref, SUM(rc.total) as visits 
    FROM ref_counts rc
    JOIN refs r ON rc.ref_id = r.ref_id
    WHERE rc.hour >= datetime('now', '-7 days')
      AND r.ref IS NOT NULL 
      AND r.ref != ''
    GROUP BY r.ref 
    ORDER BY visits DESC 
    LIMIT 5;
" | while IFS='|' read -r ref visits; do
    [ -n "$ref" ] && echo "  • ${ref} — ${visits}"
done)

# Set defaults if empty
[ -z "$TOP_PAGES" ] && TOP_PAGES="  • No page data available"
[ -z "$TOP_REFERRERS" ] && TOP_REFERRERS="  • Direct traffic only"

# Build Mattermost message (text format with markdown)
# Use temp file to avoid heredoc/Python stdin issues
TMP_MSG=$(mktemp)
trap "rm -f $TMP_MSG" EXIT

{
    echo "@here"
    echo ""
    echo "📊 **Weekly Analytics Report (Portfolio)**"
    echo ""
    echo "*Period:* ${START_DATE} → ${END_DATE}"
    echo ""
    echo "---"
    echo ""
    echo "**Total Pageviews:** ${TOTAL_PAGEVIEWS}"
    echo ""
    echo "**Top Pages:**"
    echo "$TOP_PAGES"
    echo "**Top Referrers:**"
    echo "$TOP_REFERRERS"
    echo ""
    echo "See full analytics at: https://analytics.gmojsoski.com"
} > "$TMP_MSG"

# Create JSON payload using Python (read from temp file) with bot username
PAYLOAD=$(python3 -c "import json; f=open('$TMP_MSG', 'r'); msg=f.read(); f.close(); print(json.dumps({'username': 'Analytics Bot', 'text': msg}, ensure_ascii=False))")

# Send to Mattermost (Slack-compatible format)
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD" \
    "$MATTERMOST_WEBHOOK_URL")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ] && [ "$BODY" = "ok" ]; then
    echo "✓ Weekly analytics report sent to Mattermost"
else
    echo "✗ Failed to send analytics report (HTTP $HTTP_CODE: $BODY)"
    exit 1
fi
