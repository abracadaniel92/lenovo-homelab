#!/bin/bash
# Pi Health Monitoring Script
# Sends system health report to Slack webhook

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"

# Get uptime
UPTIME=$(uptime -p | sed 's/up //')
UPTIME_DETAILED=$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1" "$2" "$3}' | sed 's/^ *//')

# Get load average
LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' | awk '{print $1", "$2", "$3}')

# Get CPU temperature (Raspberry Pi)
if command -v vcgencmd > /dev/null 2>&1; then
    TEMP=$(vcgencmd measure_temp | sed 's/temp=//')
elif [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP=$(echo "scale=1; $TEMP_RAW/1000" | bc)"'C"
else
    TEMP="N/A"
fi

# Get CPU usage
if command -v top > /dev/null 2>&1; then
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
else
    CPU_USAGE="N/A"
fi

# Get storage usage
STORAGE=$(df -h / | awk 'NR==2 {print $3" used ("$5") of "$2}')

# Get SMART status for drives
SMART_INFO=""
if command -v smartctl > /dev/null 2>&1; then
    for drive in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -b "$drive" ]; then
            DRIVE_NAME=$(basename "$drive")
            HEALTH=$(smartctl -H "$drive" 2>/dev/null | grep "SMART Health Status" | awk '{print $6}' || smartctl -H "$drive" 2>/dev/null | grep "PASSED\|FAILED" | head -1 | awk '{print $NF}')
            TEMP_SMART=$(smartctl -A "$drive" 2>/dev/null | grep -i "Temperature_Celsius\|Temperature:" | head -1 | awk '{print $NF}')
            if [ -n "$HEALTH" ] && [ -n "$TEMP_SMART" ]; then
                SMART_INFO="${SMART_INFO}/dev/$DRIVE_NAME Health: $HEALTH, Temp: ${TEMP_SMART}°C\n"
            elif [ -n "$HEALTH" ]; then
                SMART_INFO="${SMART_INFO}/dev/$DRIVE_NAME Health: $HEALTH\n"
            fi
        fi
    done
fi

# If no SMART info found, try alternative method
if [ -z "$SMART_INFO" ]; then
    for drive in /dev/sd[a-z] /dev/nvme[0-9]n[0-9]; do
        if [ -b "$drive" ]; then
            DRIVE_NAME=$(basename "$drive")
            # Try to get basic health status
            if smartctl -H "$drive" 2>/dev/null | grep -q "PASSED\|FAILED"; then
                HEALTH=$(smartctl -H "$drive" 2>/dev/null | grep -E "PASSED|FAILED" | head -1 | awk '{print $NF}')
                TEMP_SMART=$(smartctl -A "$drive" 2>/dev/null | grep -i "Temperature" | head -1 | awk '{print $(NF-1)}')
                if [ -n "$HEALTH" ]; then
                    if [ -n "$TEMP_SMART" ]; then
                        SMART_INFO="${SMART_INFO}/dev/$DRIVE_NAME Health: $HEALTH, Temp: ${TEMP_SMART}°C\n"
                    else
                        SMART_INFO="${SMART_INFO}/dev/$DRIVE_NAME Health: $HEALTH\n"
                    fi
                fi
            fi
        fi
    done
fi

# Format SMART info (remove trailing newline)
SMART_INFO=$(echo -e "$SMART_INFO" | sed '/^$/d' | head -5)

# Build message
MESSAGE=":stethoscope: Pi Health Report\n\n"
MESSAGE="${MESSAGE}• Uptime: ${UPTIME_DETAILED}\n"
MESSAGE="${MESSAGE}• Load: ${LOAD}\n"
MESSAGE="${MESSAGE}• Temp: ${TEMP}\n"
if [ "$CPU_USAGE" != "N/A" ]; then
    MESSAGE="${MESSAGE}• CPU: ${CPU_USAGE}\n"
fi
MESSAGE="${MESSAGE}• Storage: ${STORAGE}\n"

if [ -n "$SMART_INFO" ]; then
    MESSAGE="${MESSAGE}\nCurrent SMART status of your drives:\n"
    MESSAGE="${MESSAGE}${SMART_INFO}"
fi

# Send to Slack
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\": \"$(echo -e "$MESSAGE")\"}" \
    "$SLACK_WEBHOOK_URL" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Health report sent to Slack"
else
    echo "✗ Failed to send health report to Slack"
    exit 1
fi










