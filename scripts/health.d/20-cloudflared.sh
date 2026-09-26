#!/bin/bash
# 20-cloudflared.sh: Health check for Cloudflare tunnel

# Check external access (subdomain downtime detection)
EXTERNAL_DOWN=false
if ! check_external_access "gmojsoski.com"; then
    log "WARNING: External access down (gmojsoski.com not accessible)"
    EXTERNAL_DOWN=true
fi

if [ "$EXTERNAL_DOWN" = true ]; then
    # NOT `local`: modules are source'd at the engine's top level, not inside a
    # function, where `local` errors out and assigns nothing. That sent an alert
    # with an empty title and empty body for the single most critical failure
    # this homelab has, the one that pages @all.
    slack_title="🚨 CRITICAL: External Access Down"
    slack_message="@all

*Domain:* gmojsoski.com
*Status:* Not accessible (502/404/503)
*Action:* Running fix-external-access.sh automatically

*Check log:*
\`sudo tail -50 /var/log/enhanced-health-check.log\`"
    send_slack_notification "$slack_title" "$slack_message" "🚨"

    # Via /opt/homelab: the literal path contains a space, and that is what
    # killed this whole layer for eight months (troubleshooting-log 2026-09-25).
    FIX_SCRIPT="/opt/homelab/restart services/fix-external-access.sh"
    if [ -f "$FIX_SCRIPT" ]; then
        log "Running fix script: $FIX_SCRIPT"
        bash "$FIX_SCRIPT"

        # Verify if back up
        sleep 10
        if check_external_access "gmojsoski.com"; then
            log "SUCCESS: External access restored"
            send_slack_notification "✅ External Access Restored" "External access to gmojsoski.com has been restored." "✅"
        else
            log "ERROR: Fix script did not restore external access"
        fi
    else
        log "ERROR: Fix script not found at $FIX_SCRIPT"
        send_slack_notification "❌ Fix Script Not Found" "@here The fix-external-access.sh script was not found. Manual intervention required." "❌"
    fi
fi
