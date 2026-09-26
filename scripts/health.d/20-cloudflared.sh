#!/bin/bash
# 20-cloudflared.sh: Health check for Cloudflare tunnel

# Despite the filename, this module used to check only whether gmojsoski.com
# answered from outside, and never whether cloudflared itself was running.
# enhanced-health-check.sh restarts the container when `docker ps` shows it
# gone; the modular rewrite dropped that. A dead tunnel was therefore only
# caught indirectly by the external probe below, whose response is to run the
# heavyweight fix-external-access.sh rather than just starting the container.
CLOUDFLARED_DIR="/home/docker-projects/cloudflared"
if [ "$(docker ps --filter "name=cloudflared" --format '{{.Names}}' 2>/dev/null | wc -l)" -lt 1 ]; then
    log "CRITICAL: cloudflared container not running. Starting..."
    if [ -d "$CLOUDFLARED_DIR" ]; then
        (cd "$CLOUDFLARED_DIR" && docker compose up -d) >/dev/null 2>&1
        sleep 5
    else
        log "ERROR: cloudflared compose dir missing: $CLOUDFLARED_DIR"
    fi
    if [ "$(docker ps --filter "name=cloudflared" --format '{{.Names}}' 2>/dev/null | wc -l)" -ge 1 ]; then
        log "SUCCESS: cloudflared restarted"
        send_slack_notification "✅ Cloudflare tunnel recovered" \
            "cloudflared was not running and has been restarted." "✅"
    else
        log "ERROR: cloudflared failed to start"
        send_slack_notification "🚨 Cloudflare tunnel down" \
            "@all cloudflared is not running and could not be started. All external access is offline." "🚨"
    fi
fi

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
