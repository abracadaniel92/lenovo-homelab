#!/bin/bash
# Pi Health Monitoring Script
# Sends system health report to Mattermost webhook (Slack-compatible format)
# Runs every 5 days via systemd timer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Prioritize monitoring-specific webhook (Mattermost or legacy Slack)
[ -n "$MONITORING_MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$MONITORING_MATTERMOST_WEBHOOK_URL"
[ -n "$MONITORING_SLACK_WEBHOOK_URL" ] && [ -z "$MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$MONITORING_SLACK_WEBHOOK_URL"

# Default Mattermost webhook for uptime/health monitoring
MATTERMOST_WEBHOOK_URL="${MATTERMOST_WEBHOOK_URL:-https://mattermost.gmojsoski.com/hooks/bettcnqps7ngpfp74i6zux5s8w}"

# Get hostname
HOSTNAME=$(hostname)

# Get uptime
UPTIME=$(uptime -p | sed 's/up //')

# Get load average
LOAD=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')

# Get CPU temperature
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP=$(echo "scale=1; $TEMP_RAW/1000" | bc)"°C"
elif command -v vcgencmd > /dev/null 2>&1; then
    TEMP=$(vcgencmd measure_temp | sed 's/temp=//')
else
    TEMP="N/A"
fi

# Get memory usage
MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')

# Get storage usage for key mounts
get_disk_usage() {
    local mount=$1
    local name=$2
    if mountpoint -q "$mount" 2>/dev/null || [ -d "$mount" ]; then
        local info=$(df -h "$mount" 2>/dev/null | awk 'NR==2 {print $3" / "$2" ("$5")"}')
        [ -n "$info" ] && echo "  • $name: $info"
    fi
}

DISK_ROOT=$(get_disk_usage "/" "Root")
DISK_SSD=$(get_disk_usage "/mnt/ssd" "SSD")

# Get Docker containers status
DOCKER_TOTAL=$(docker ps -a --format '{{.Names}}' 2>/dev/null | wc -l)
DOCKER_RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
DOCKER_UNHEALTHY=$(docker ps --filter "health=unhealthy" --format '{{.Names}}' 2>/dev/null | wc -l)

# Get SMART status for drives
SMART_INFO=""
if command -v smartctl > /dev/null 2>&1; then
    for drive in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -b "$drive" ]; then
            DRIVE_NAME=$(basename "$drive")
            # Get health status
            HEALTH=$(sudo smartctl -H "$drive" 2>/dev/null | grep -E "PASSED|FAILED|OK" | head -1 | awk '{print $NF}')
            # Get temperature
            TEMP_DRIVE=$(sudo smartctl -A "$drive" 2>/dev/null | grep -i "Temperature" | head -1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/) {print $i; exit}}')
            
            if [ -n "$HEALTH" ]; then
                if [ -n "$TEMP_DRIVE" ]; then
                    SMART_INFO="${SMART_INFO}  • ${DRIVE_NAME}: ${HEALTH} (${TEMP_DRIVE}°C)\n"
                else
                    SMART_INFO="${SMART_INFO}  • ${DRIVE_NAME}: ${HEALTH}\n"
                fi
            fi
        fi
    done
fi

# Determine health status emoji
if [ "$DOCKER_UNHEALTHY" -gt 0 ]; then
    STATUS_EMOJI="⚠️"
    STATUS_TEXT="Warning: $DOCKER_UNHEALTHY unhealthy container(s)"
else
    STATUS_EMOJI="✅"
    STATUS_TEXT="All systems operational"
fi

# Build Mattermost message (text format with markdown)
# Use temp file to avoid heredoc/Python stdin issues
TMP_MSG=$(mktemp)
trap "rm -f $TMP_MSG" EXIT

{
    echo "🖥️ **Server Health Report: ${HOSTNAME}**"
    echo ""
    echo "${STATUS_EMOJI} ${STATUS_TEXT}"
    echo ""
    echo "---"
    echo ""
    echo "**System Information:**"
    echo "• *Uptime:* ${UPTIME}"
    echo "• *CPU Temp:* ${TEMP}"
    echo "• *Load Avg:* ${LOAD}"
    echo "• *Memory:* ${MEM_USED}/${MEM_TOTAL} (${MEM_PERCENT}%)"
    echo ""
    echo "**Storage:**"
    [ -n "$DISK_ROOT" ] && echo "$DISK_ROOT"
    [ -n "$DISK_SSD" ] && echo "$DISK_SSD"
    echo ""
    echo "**Docker:**"
    echo "• Running: ${DOCKER_RUNNING}/${DOCKER_TOTAL}"
    echo "• Unhealthy: ${DOCKER_UNHEALTHY}"
    if [ -n "$SMART_INFO" ]; then
        echo ""
        echo "**Drive Health:**"
        echo -e "$SMART_INFO" | sed 's/^  • /• /'
    fi
} > "$TMP_MSG"

# Create JSON payload using Python (read from temp file)
PAYLOAD=$(python3 -c "import json; f=open('$TMP_MSG', 'r'); msg=f.read(); f.close(); print(json.dumps({'text': msg}, ensure_ascii=False))")

# Send to Mattermost (Slack-compatible format)
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD" \
    "$MATTERMOST_WEBHOOK_URL")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ] && [ "$BODY" = "ok" ]; then
    echo "✓ Health report sent to Mattermost"
else
    echo "✗ Failed to send health report (HTTP $HTTP_CODE: $BODY)"
    exit 1
fi
