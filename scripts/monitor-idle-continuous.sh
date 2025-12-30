#!/bin/bash
###############################################################################
# Continuous Idle Monitoring
# Monitors system activity and logs when system appears to go idle
# Run this in the background to track idle events
###############################################################################

LOG_FILE="/var/log/idle-monitor.log"
CHECK_INTERVAL=60  # Check every 60 seconds
IDLE_THRESHOLD=0.05  # CPU load below this is considered idle

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting continuous idle monitoring (checking every ${CHECK_INTERVAL}s)"

while true; do
    # Check if system is in sleep/suspend state
    if systemctl is-active sleep.target > /dev/null 2>&1 || \
       systemctl is-active suspend.target > /dev/null 2>&1 || \
       systemctl is-active hibernate.target > /dev/null 2>&1; then
        log "⚠️  ALERT: System entered sleep/suspend state!"
    fi
    
    # Check CPU load
    if command -v uptime > /dev/null 2>&1; then
        LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        if [ -n "$LOAD_AVG" ] && command -v bc > /dev/null 2>&1; then
            if (( $(echo "$LOAD_AVG < $IDLE_THRESHOLD" | bc -l) )); then
                log "⚠️  IDLE DETECTED: CPU load very low ($LOAD_AVG)"
            fi
        fi
    fi
    
    # Check network activity
    if command -v ss > /dev/null 2>&1; then
        CONN_COUNT=$(ss -tun 2>/dev/null | wc -l)
        if [ "$CONN_COUNT" -lt 3 ]; then
            log "⚠️  IDLE DETECTED: Very few network connections ($CONN_COUNT)"
        fi
    fi
    
    # Check Docker containers
    if command -v docker > /dev/null 2>&1; then
        STOPPED_CONTAINERS=$(docker ps -a --filter "status=exited" --format "{{.Names}}" | wc -l)
        if [ "$STOPPED_CONTAINERS" -gt 0 ]; then
            log "⚠️  WARNING: $STOPPED_CONTAINERS Docker container(s) are stopped"
        fi
    fi
    
    # Check systemd services
    FAILED_SERVICES=$(systemctl --failed --no-legend | wc -l)
    if [ "$FAILED_SERVICES" -gt 0 ]; then
        log "⚠️  WARNING: $FAILED_SERVICES systemd service(s) have failed"
    fi
    
    sleep "$CHECK_INTERVAL"
done












