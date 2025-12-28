#!/bin/bash
###############################################################################
# Check if Machine is Going Idle
# Monitors system activity and power management states
###############################################################################

echo "=========================================="
echo "System Idle and Power Management Check"
echo "=========================================="
echo ""

# 1. Check system uptime
echo "1. SYSTEM UPTIME:"
uptime
echo ""

# 2. Check last boot time
echo "2. LAST BOOT TIME:"
last reboot | head -1
who -b
echo ""

# 3. Check power management settings
echo "3. POWER MANAGEMENT SETTINGS:"
echo "--- logind.conf ---"
if [ -f /etc/systemd/logind.conf ]; then
    cat /etc/systemd/logind.conf | grep -E "HandlePowerKey|HandleSuspendKey|HandleHibernateKey|HandleLidSwitch|IdleAction" || echo "No power management settings found"
fi
if [ -d /etc/systemd/logind.conf.d ]; then
    echo "--- logind.conf.d overrides ---"
    for file in /etc/systemd/logind.conf.d/*.conf; do
        if [ -f "$file" ]; then
            echo "File: $file"
            cat "$file"
        fi
    done
fi
echo ""

# 4. Check if system is currently sleeping/suspended
echo "4. CURRENT SLEEP/SUSPEND STATE:"
if systemctl is-active sleep.target > /dev/null 2>&1; then
    echo "⚠️  WARNING: System is in sleep.target (sleeping)"
else
    echo "✓ System is NOT sleeping"
fi

if systemctl is-active suspend.target > /dev/null 2>&1; then
    echo "⚠️  WARNING: System is in suspend.target (suspended)"
else
    echo "✓ System is NOT suspended"
fi

if systemctl is-active hibernate.target > /dev/null 2>&1; then
    echo "⚠️  WARNING: System is in hibernate.target (hibernated)"
else
    echo "✓ System is NOT hibernated"
fi
echo ""

# 5. Check systemd sleep inhibitor locks
echo "5. SLEEP INHIBITOR LOCKS:"
if command -v systemd-inhibit > /dev/null 2>&1; then
    systemd-inhibit --list
else
    echo "systemd-inhibit not available"
fi
echo ""

# 6. Check CPU activity (last 1 minute average)
echo "6. CPU ACTIVITY:"
if command -v top > /dev/null 2>&1; then
    echo "CPU load averages:"
    uptime | awk -F'load average:' '{print $2}'
    echo ""
    echo "Top CPU consuming processes:"
    top -bn1 | head -20
else
    echo "top command not available"
fi
echo ""

# 7. Check network activity
echo "7. NETWORK ACTIVITY:"
if command -v ss > /dev/null 2>&1; then
    echo "Active network connections:"
    ss -tun | wc -l | xargs echo "Total connections:"
    echo ""
    echo "Listening ports:"
    ss -tlnp | grep -E ":(8080|8081|8088|8091|5000|8000|3001|8443)" || echo "No service ports found listening"
else
    echo "ss command not available"
fi
echo ""

# 8. Check process activity
echo "8. PROCESS ACTIVITY:"
echo "Total running processes: $(ps aux | wc -l)"
echo "Docker processes: $(ps aux | grep -c docker || echo 0)"
echo ""

# 9. Check systemd timers and services
echo "9. SYSTEMD TIMERS (may indicate scheduled activity):"
systemctl list-timers --all | head -20
echo ""

# 10. Check for wake-on-lan and other power features
echo "10. WAKE EVENTS (if available):"
if [ -f /sys/power/wakeup_count ]; then
    echo "Wakeup count: $(cat /sys/power/wakeup_count 2>/dev/null || echo 'N/A')"
fi
if [ -d /sys/class/rtc ]; then
    echo "RTC devices:"
    ls -la /sys/class/rtc/ 2>/dev/null || echo "No RTC devices found"
fi
echo ""

# 11. Check disk activity
echo "11. DISK ACTIVITY:"
if command -v iostat > /dev/null 2>&1; then
    iostat -x 1 2 | tail -n +4
elif [ -f /proc/diskstats ]; then
    echo "Recent disk I/O (from /proc/diskstats):"
    cat /proc/diskstats | head -5
else
    echo "Disk stats not available"
fi
echo ""

# 12. Check memory usage
echo "12. MEMORY USAGE:"
free -h
echo ""

# 13. Check for automatic suspend/sleep triggers
echo "13. AUTOMATIC SUSPEND CONFIGURATION:"
if [ -f /etc/systemd/sleep.conf ]; then
    echo "sleep.conf settings:"
    cat /etc/systemd/sleep.conf
fi
if [ -d /etc/systemd/sleep.conf.d ]; then
    echo "sleep.conf.d overrides:"
    cat /etc/systemd/sleep.conf.d/*.conf 2>/dev/null || echo "No overrides"
fi
echo ""

# 14. Check kernel messages for sleep/suspend events
echo "14. RECENT KERNEL MESSAGES (sleep/suspend related):"
dmesg | grep -iE "suspend|sleep|hibernate|wake|idle" | tail -20 || echo "No sleep-related kernel messages found"
echo ""

# 15. Check systemd journal for sleep events
echo "15. RECENT SYSTEMD JOURNAL (sleep/suspend related):"
journalctl -k --since "1 hour ago" | grep -iE "suspend|sleep|hibernate|wake|idle" | tail -20 || echo "No sleep-related journal entries found"
echo ""

# 16. Check if system is actually idle (no user activity)
echo "16. USER ACTIVITY:"
echo "Logged in users:"
who
echo ""
echo "Last login times:"
lastlog | head -5
echo ""

# 17. Check for automatic power management in BIOS/UEFI (if accessible)
echo "17. ACPI POWER STATES:"
if [ -d /sys/power ]; then
    echo "Available power states:"
    cat /sys/power/state 2>/dev/null || echo "Cannot read power states"
    echo ""
    echo "Current power state:"
    cat /sys/power/mem_sleep 2>/dev/null || echo "Cannot determine current state"
fi
echo ""

# 18. Check for scheduled tasks that might affect system
echo "18. CRON JOBS (may indicate scheduled activity):"
crontab -l 2>/dev/null || echo "No user crontab"
if [ -f /etc/crontab ]; then
    echo "System crontab:"
    cat /etc/crontab
fi
echo ""

# 19. Check Docker container activity
echo "19. DOCKER CONTAINER STATUS:"
if command -v docker > /dev/null 2>&1; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.State}}"
    echo ""
    echo "Docker stats (last 5 seconds):"
    timeout 5 docker stats --no-stream 2>/dev/null || echo "Docker stats unavailable"
else
    echo "Docker not available"
fi
echo ""

# 20. Summary and recommendations
echo "=========================================="
echo "SUMMARY AND RECOMMENDATIONS"
echo "=========================================="
echo ""

# Check if system might be going idle
IDLE_WARNING=false

if systemctl is-active sleep.target > /dev/null 2>&1 || \
   systemctl is-active suspend.target > /dev/null 2>&1 || \
   systemctl is-active hibernate.target > /dev/null 2>&1; then
    echo "⚠️  CRITICAL: System is currently in a sleep/suspend state!"
    IDLE_WARNING=true
fi

# Check CPU load
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
if [ -n "$LOAD_AVG" ]; then
    if (( $(echo "$LOAD_AVG < 0.1" | bc -l 2>/dev/null || echo 0) )); then
        echo "⚠️  WARNING: Very low CPU load ($LOAD_AVG) - system may be idle"
        IDLE_WARNING=true
    fi
fi

# Check network activity
if command -v ss > /dev/null 2>&1; then
    CONN_COUNT=$(ss -tun 2>/dev/null | wc -l)
    if [ "$CONN_COUNT" -lt 5 ]; then
        echo "⚠️  WARNING: Very few network connections ($CONN_COUNT) - may indicate idle state"
        IDLE_WARNING=true
    fi
fi

if [ "$IDLE_WARNING" = false ]; then
    echo "✓ System appears to be active and not idle"
else
    echo ""
    echo "RECOMMENDED ACTIONS:"
    echo "1. Run: sudo bash configure-power-management.sh"
    echo "2. Check: systemctl status sleep.target suspend.target hibernate.target"
    echo "3. Ensure no automatic sleep timers are configured"
fi

echo ""
echo "Check complete!"












