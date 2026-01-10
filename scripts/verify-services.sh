#!/bin/bash

# Configuration
SUBDOMAINS=("gmojsoski.com" "jellyfin.gmojsoski.com" "cloud.gmojsoski.com" "vault.gmojsoski.com" "paperless.gmojsoski.com" "files.gmojsoski.com" "zulip.gmojsoski.com" "mattermost.gmojsoski.com")
LOG_FILE="/home/goce/Desktop/Cursor projects/Pi-version-control/logs/verification.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "=== Service Verification Started at $(date) ===" | tee -a "$LOG_FILE"

FAILED=0

for sub in "${SUBDOMAINS[@]}"; do
    STATUS=$(curl -o /dev/null -s -w "%{http_code}" "https://$sub")
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "302" ]; then
        echo "✅ $sub: $STATUS" | tee -a "$LOG_FILE"
    else
        echo "❌ $sub: $STATUS" | tee -a "$LOG_FILE"
        FAILED=$((FAILED + 1))
    fi
done

if [ $FAILED -gt 0 ]; then
    echo "CRITICAL: $FAILED services are DOWN or misconfigured!" | tee -a "$LOG_FILE"
    exit 1
else
    echo "Success: All services are healthy." | tee -a "$LOG_FILE"
    exit 0
fi
