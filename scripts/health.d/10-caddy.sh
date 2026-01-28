#!/bin/bash
# 10-caddy.sh: Health check for Caddy reverse proxy

# Check Caddy (CRITICAL)
if ! check_service_http "http://localhost:8080/" 5; then
    log "CRITICAL: Caddy not responding. Restarting..."
    cd /mnt/ssd/docker-projects/caddy
    docker compose restart caddy
    sleep 5
    
    # Verify after restart
    if check_service_http "http://localhost:8080/" 5; then
        log "SUCCESS: Caddy restarted successfully"
        send_slack_notification "✅ Caddy Recovered" "Caddy was down but has been successfully restarted." "✅"
    else
        log "ERROR: Caddy failed to start!"
        send_slack_notification "🚨 CRITICAL: Caddy Restart Failed" "@all Caddy is down and restart attempt failed. Manual intervention required." "🚨"
    fi
fi
