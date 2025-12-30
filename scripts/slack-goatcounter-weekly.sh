#!/bin/bash
# GoatCounter Weekly Analytics Report Script
# Sends weekly analytics summary to Slack webhook

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# Calculate date range (last 7 days)
END_DATE=$(date +%Y-%m-%d)
START_DATE=$(date -d "7 days ago" +%Y-%m-%d)

# Find GoatCounter database
GOATCOUNTER_DB=""
if [ -f "/mnt/ssd/docker-projects/goatcounter/goatcounter-data/goatcounter.sqlite3" ]; then
    GOATCOUNTER_DB="/mnt/ssd/docker-projects/goatcounter/goatcounter-data/goatcounter.sqlite3"
elif [ -f "./goatcounter-data/goatcounter.sqlite3" ]; then
    GOATCOUNTER_DB="./goatcounter-data/goatcounter.sqlite3"
fi

# Initialize variables
TOTAL_VISITORS="0"
TOP_PAGES=""
TOP_COUNTRIES=""

# Function to query database using docker
query_db() {
    local query="$1"
    if [ -n "$GOATCOUNTER_DB" ] && [ -f "$GOATCOUNTER_DB" ]; then
        # Use nouchka/sqlite3 docker image to query the database
        # First checkpoint WAL to ensure we see all data
        docker run --rm -v "$(dirname "$GOATCOUNTER_DB"):/db" nouchka/sqlite3:latest "/db/$(basename "$GOATCOUNTER_DB")" "PRAGMA wal_checkpoint;" > /dev/null 2>&1
        # Then run the actual query
        docker run --rm -v "$(dirname "$GOATCOUNTER_DB"):/db" nouchka/sqlite3:latest "/db/$(basename "$GOATCOUNTER_DB")" "$query" 2>/dev/null
    fi
}

# Function to sum JSON array values (for hit_stats.stats column)
sum_json_array() {
    local json_array="$1"
    # Remove brackets and sum the numbers
    echo "$json_array" | sed 's/\[//;s/\]//' | tr ',' '\n' | awk '{sum+=$1} END {print sum+0}'
}

# Check if we can query the database
if [ -n "$GOATCOUNTER_DB" ] && [ -f "$GOATCOUNTER_DB" ]; then
    # Get total visitors from hit_stats (sum all stats arrays for last 7 days)
    TEMP_FILE=$(mktemp)
    query_db "SELECT stats FROM hit_stats WHERE day >= date('now', '-7 days');" 2>&1 > "$TEMP_FILE"
    
    if [ -s "$TEMP_FILE" ]; then
        TOTAL_VISITS=0
        while read -r stats_array; do
            if [ -n "$stats_array" ]; then
                COUNT=$(sum_json_array "$stats_array")
                TOTAL_VISITS=$((TOTAL_VISITS + COUNT))
            fi
        done < "$TEMP_FILE"
        TOTAL_VISITORS=$TOTAL_VISITS
    fi
    rm -f "$TEMP_FILE"
    
    # Get top pages from hit_stats - aggregate by path
    TEMP_FILE=$(mktemp)
    query_db "SELECT p.path, hs.stats FROM hit_stats hs JOIN paths p ON hs.path_id = p.path_id WHERE hs.day >= date('now', '-7 days');" 2>&1 > "$TEMP_FILE"
    
    if [ -s "$TEMP_FILE" ]; then
        # Use a temporary file to aggregate by path
        TEMP_AGGREGATE=$(mktemp)
        while IFS='|' read -r path stats; do
            if [ -n "$path" ] && [ -n "$stats" ]; then
                COUNT=$(sum_json_array "$stats")
                if [ "$COUNT" -gt 0 ]; then
                    echo "$path|$COUNT" >> "$TEMP_AGGREGATE"
                fi
            fi
        done < "$TEMP_FILE"
        
        # Sort and get top 5
        if [ -s "$TEMP_AGGREGATE" ]; then
            sort -t'|' -k2 -rn "$TEMP_AGGREGATE" | head -5 | while IFS='|' read -r path visits; do
                if [ -z "$path" ]; then
                    path="/"
                fi
                if [ -z "$TOP_PAGES" ]; then
                    TOP_PAGES="${path} — ${visits} visits"
                else
                    TOP_PAGES="${TOP_PAGES}\n${path} — ${visits} visits"
                fi
            done
        fi
        rm -f "$TEMP_AGGREGATE"
    fi
    rm -f "$TEMP_FILE"
    
    # Get top countries from location_stats
    TEMP_FILE=$(mktemp)
    query_db "SELECT l.country_name, SUM(ls.count) as visits FROM location_stats ls JOIN locations l ON ls.location = l.iso_3166_2 WHERE ls.day >= date('now', '-7 days') GROUP BY l.country_name ORDER BY visits DESC LIMIT 5;" 2>&1 > "$TEMP_FILE"
    
    # If no results with date filter, try without date filter
    if [ ! -s "$TEMP_FILE" ]; then
        query_db "SELECT l.country_name, SUM(ls.count) as visits FROM location_stats ls JOIN locations l ON ls.location = l.iso_3166_2 GROUP BY l.country_name ORDER BY visits DESC LIMIT 5;" 2>&1 > "$TEMP_FILE"
    fi
    
    if [ -s "$TEMP_FILE" ]; then
        while IFS='|' read -r country visits; do
            if [ -n "$country" ] && [ "$country" != " " ] && [ -n "$visits" ]; then
                if [ -z "$TOP_COUNTRIES" ]; then
                    TOP_COUNTRIES="${country} — ${visits} visits"
                else
                    TOP_COUNTRIES="${TOP_COUNTRIES}${country} — ${visits} visits"
                fi
            fi
        done < "$TEMP_FILE"
    fi
    rm -f "$TEMP_FILE"
fi

# Set defaults if empty
if [ -z "$TOP_PAGES" ]; then
    if [ "$TOTAL_VISITORS" != "0" ] && [ -n "$TOTAL_VISITORS" ]; then
        TOP_PAGES="/ — ${TOTAL_VISITORS} visits"
    else
        TOP_PAGES="/ — 0 visits"
    fi
fi

if [ -z "$TOP_COUNTRIES" ]; then
    TOP_COUNTRIES="No data available"
fi

# Build the message
MESSAGE=":bar_chart: Weekly Analytics Report (${START_DATE} → ${END_DATE})\n\n"
MESSAGE="${MESSAGE}• Total visitors: ${TOTAL_VISITORS:-0}\n\n"
MESSAGE="${MESSAGE}Top pages:\n${TOP_PAGES}\n\n"
MESSAGE="${MESSAGE}Top countries:\n${TOP_COUNTRIES}"

# Send to Slack
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\": \"$(echo -e "$MESSAGE")\"}" \
    "$SLACK_WEBHOOK_URL" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Weekly analytics report sent to Slack"
else
    echo "✗ Failed to send analytics report to Slack"
    exit 1
fi
