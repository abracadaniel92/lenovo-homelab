#!/bin/bash
###############################################################################
# Test Mattermost Webhook with Bot Username
# This script tests if the username field in the payload works correctly
###############################################################################

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Use the same webhook URL as enhanced-health-check.sh
[ -n "$MONITORING_MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$MONITORING_MATTERMOST_WEBHOOK_URL"
[ -n "$MONITORING_SLACK_WEBHOOK_URL" ] && [ -z "$MATTERMOST_WEBHOOK_URL" ] && MATTERMOST_WEBHOOK_URL="$MONITORING_SLACK_WEBHOOK_URL"
MATTERMOST_WEBHOOK_URL="${MATTERMOST_WEBHOOK_URL:-https://mattermost.gmojsoski.com/hooks/bettcnqps7ngpfp74i6zux5s8w}"

echo "Testing Mattermost webhook with bot username..."
echo "Webhook URL: $MATTERMOST_WEBHOOK_URL"
echo ""

# Test with username field (blocks format)
echo "Test 1: Sending message with username 'System Bot' (blocks format)..."
PAYLOAD_WITH_USERNAME='{
    "username": "System Bot",
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "🧪 Test Message with Bot Username",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "This message should appear as *System Bot* instead of your username.\n\nIf you see this message with the username *System Bot*, then the configuration is working correctly!"
            }
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "Time: '"$(date '+%Y-%m-%d %H:%M:%S')"' | Test Script"
                }
            ]
        }
    ]
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD_WITH_USERNAME" \
    "$MATTERMOST_WEBHOOK_URL" 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ] && [ "$BODY" = "ok" ]; then
    echo "✅ Message sent successfully!"
    echo ""
    echo "Check your Mattermost channel - the message should appear as 'System Bot'"
else
    echo "❌ Failed to send message (HTTP $HTTP_CODE: $BODY)"
    exit 1
fi

# Test with simple text format
echo ""
echo "Test 2: Sending message with username 'System Bot' (text format)..."
PAYLOAD_TEXT=$(python3 -c "import json; print(json.dumps({'username': 'System Bot', 'text': '🧪 **Test Message (Text Format)**\n\nThis is a simple text message that should appear as *System Bot*.\n\nTime: $(date +%Y-%m-%d\ %H:%M:%S)'}, ensure_ascii=False))")

RESPONSE2=$(curl -s -w "\n%{http_code}" -X POST -H 'Content-type: application/json' \
    --data "$PAYLOAD_TEXT" \
    "$MATTERMOST_WEBHOOK_URL" 2>/dev/null)

HTTP_CODE2=$(echo "$RESPONSE2" | tail -1)
BODY2=$(echo "$RESPONSE2" | head -n -1)

if [ "$HTTP_CODE2" = "200" ] && [ "$BODY2" = "ok" ]; then
    echo "✅ Text message sent successfully!"
    echo ""
    echo "Check your Mattermost channel - both messages should appear as 'System Bot'"
else
    echo "❌ Failed to send text message (HTTP $HTTP_CODE2: $BODY2)"
fi

echo ""
echo "📋 Summary:"
echo "If the messages appear as 'System Bot' in Mattermost, the username field is working correctly."
echo "If they still show as your username ('goce'), Mattermost might be ignoring the username field."
echo ""
echo "In that case, you may need to:"
echo "1. Check Mattermost version (username override might require certain permissions)"
echo "2. Create a bot account instead of using webhooks"
echo "3. Or configure the webhook display name in System Console (if available in your version)"

