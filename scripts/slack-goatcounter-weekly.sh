#!/bin/bash
###############################################################################
# GoatCounter Weekly Analytics Report Script
# Sends weekly analytics summary to Slack webhook
# Runs every Sunday at 10 AM via systemd timer
###############################################################################

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Prioritize analytics-specific webhook
[ -n "$ANALYTICS_SLACK_WEBHOOK_URL" ] && SLACK_WEBHOOK_URL="$ANALYTICS_SLACK_WEBHOOK_URL"

if [ -z "$SLACK_WEBHOOK_URL" ]; then
    echo "ERROR: SLACK_WEBHOOK_URL or ANALYTICS_SLACK_WEBHOOK_URL is not set. Please check scripts/.env"
    exit 1
fi

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

# Build Slack message with blocks for better formatting
# Note: Unique Visitors removed as it requires non-aggregated data (hits table)
read -r -d '' PAYLOAD << EOF || true
{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "📊 Weekly Analytics Report (Portfolio)",
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
                    "text": "*Total Pageviews*\n${TOTAL_PAGEVIEWS}"
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
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "See full analytics at <https://analytics.gmojsoski.com|analytics.gmojsoski.com>"
                }
            ]
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
