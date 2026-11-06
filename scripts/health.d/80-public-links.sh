#!/bin/bash
# 80-public-links.sh: once a day, check the links outsiders actually click.
#
# Sourced by health-check-engine.sh, so log() and send_slack_notification() come
# from there. No `local` here: this runs at top level (see test-health-modules.sh).
#
# Why this exists: on 2026-11-06 the Cal booking link on the portfolio turned out
# to have 404'd since 2026-09-27 while every check read green. They only hit each
# site's front page, and Cal's front page is a login redirect whether or not
# public booking pages work. So this follows redirects and wants a final 200 on
# the exact URLs people use.
#
# ponytail: rides the hourly health-check timer and only acts in the 09:xx run.
# Ceiling: if that run is missed (server down at 09:33), the day is skipped.
# Upgrade path: a stamp file, or its own systemd timer.

if [ "$(date +%H)" = "${PUBLIC_LINKS_HOUR:-09}" ]; then
    # An array, not a string: the Cal URL has `?`, which word-splitting would glob.
    # Tests preset public_links; production uses the list below.
    if [ -z "${public_links[*]:-}" ]; then
        public_links=(
            "https://gmojsoski.com/"
            "https://gmojsoski.com/files/GoceMojsoskiCV.pdf"
            "https://cal.gmojsoski.com/gmojsoski/30min?user=gmojsoski&overlayCalendar=true"
        )
    fi
    public_links_failed=""
    for public_link in "${public_links[@]}"; do
        public_link_status=$(curl -sL -o /dev/null -m 20 --retry 2 -w '%{http_code}' "$public_link")
        [ "$public_link_status" = "200" ] || public_links_failed+="$public_link -> $public_link_status"$'\n'
    done
    if [ -n "$public_links_failed" ]; then
        log "WARNING: public link(s) broken: $public_links_failed"
        send_slack_notification "🚨 Public link broken" "$public_links_failed" "🚨"
    else
        log "Public links: all ${#public_links[@]} return 200"
    fi
fi
