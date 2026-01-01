#!/bin/bash
# GoatCounter Weekly Analytics Report Script
# Sends weekly analytics summary to Slack webhook
# Runs every Sunday at 10 AM via systemd timer

set -e

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"
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

# Get total pageviews (sum of all hourly stats arrays)
TOTAL_PAGEVIEWS=$(query_db "
    SELECT COALESCE(SUM(
        CAST(REPLACE(REPLACE(REPLACE(stats, '[', ''), ']', ''), ',', '+') AS INTEGER)
    ), 0) 
    FROM hit_stats 
    WHERE day >= date('now', '-7 days');
" | head -1)

# Fallback: count rows if above fails
if [ -z "$TOTAL_PAGEVIEWS" ] || [ "$TOTAL_PAGEVIEWS" = "0" ]; then
    TOTAL_PAGEVIEWS=$(query_db "SELECT COUNT(*) FROM hit_stats WHERE day >= date('now', '-7 days');" | head -1)
fi

# Get unique visitors (sessions)
UNIQUE_VISITORS=$(query_db "
    SELECT COUNT(DISTINCT session_id) 
    FROM hits 
    WHERE created_at >= datetime('now', '-7 days');
" | head -1)
UNIQUE_VISITORS=${UNIQUE_VISITORS:-0}

# Get top 5 pages
TOP_PAGES=$(query_db "
    SELECT p.path, COUNT(*) as visits 
    FROM hits h 
    JOIN paths p ON h.path_id = p.path_id 
    WHERE h.created_at >= datetime('now', '-7 days')
    GROUP BY p.path 
    ORDER BY visits DESC 
    LIMIT 5;
" | while IFS='|' read -r path visits; do
    [ -n "$path" ] && echo "  • ${path:-/} — ${visits} views"
done)

# Get top 5 referrers (excluding direct)
TOP_REFERRERS=$(query_db "
    SELECT ref, COUNT(*) as visits 
    FROM hits 
    WHERE created_at >= datetime('now', '-7 days') 
      AND ref IS NOT NULL 
      AND ref != ''
    GROUP BY ref 
    ORDER BY visits DESC 
    LIMIT 5;
" | while IFS='|' read -r ref visits; do
    [ -n "$ref" ] && echo "  • ${ref} — ${visits}"
done)

# Set defaults if empty
[ -z "$TOP_PAGES" ] && TOP_PAGES="  • No page data available"
[ -z "$TOP_REFERRERS" ] && TOP_REFERRERS="  • Direct traffic only"

# Build Slack message with blocks for better formatting
read -r -d '' PAYLOAD << EOF || true
{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "📊 Weekly Analytics Report",
                "emoji": true
            }
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "plain_text",
                    "text": "${START_DATE} → ${END_DATE}"
                }
            ]
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "fields": [
                {
                    "type": "mrkdwn",
                    "text": "*Total Pageviews*\n${TOTAL_PAGEVIEWS:-0}"
                },
                {
                    "type": "mrkdwn",
                    "text": "*Unique Visitors*\n${UNIQUE_VISITORS:-0}"
                }
            ]
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Top Pages*\n${TOP_PAGES}"
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Top Referrers*\n${TOP_REFERRERS}"
            }
        }
    ]
}
EOF

# Send to Slack
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD" \
    "$SLACK_WEBHOOK_URL")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ] && [ "$BODY" = "ok" ]; then
    echo "✓ Weekly analytics report sent to Slack"
else
    echo "✗ Failed to send analytics report (HTTP $HTTP_CODE: $BODY)"
    exit 1
fi
