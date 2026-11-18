#!/bin/bash
# 85-ics-cache.sh: alert when Cal's cached Outlook feed stops refreshing.
#
# Sourced by health-check-engine.sh, so log() and send_slack_notification() come
# from there. No `local` here: this runs at top level (see test-health-modules.sh).
#
# Why: scripts/cache-outlook-ics.sh refreshes the file daily at 06:00 and keeps
# the old copy when a download fails. Without this check a broken cron would
# leave Cal showing weeks-old Outlook busy times with nothing looking wrong.

ics_cache_file="${ICS_CACHE_FILE:-/home/docker-projects/calcom/ics-cache/outlook.ics}"

# -mmin +2880 = older than 48 h, i.e. two daily refreshes missed.
if [ ! -f "$ics_cache_file" ] || [ -n "$(find "$ics_cache_file" -mmin +2880)" ]; then
    log "WARNING: Cal Outlook ICS cache is missing or older than 48 h: $ics_cache_file"
    send_slack_notification "🚨 Cal Outlook calendar cache is stale" \
        "$ics_cache_file is missing or older than 48 h. Run /opt/homelab/scripts/cache-outlook-ics.sh and check its error." "🚨"
fi
