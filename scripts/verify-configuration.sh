#!/bin/bash
###############################################################################
# Configuration Verification Script
# Checks if all services and scripts are configured correctly
###############################################################################

echo "=========================================="
echo "Configuration Verification"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
    local name=$1
    local status=$2
    if [ "$status" = "0" ] || [ "$status" = "ok" ] || [ "$status" = "active" ] || [ "$status" = "enabled" ]; then
        echo -e "${GREEN}✓${NC} $name"
        return 0
    else
        echo -e "${RED}✗${NC} $name"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

warn() {
    local name=$1
    echo -e "${YELLOW}⚠${NC} $name"
    WARNINGS=$((WARNINGS + 1))
}

echo "1. Checking Systemd Services..."
echo ""

# Check if services exist
SERVICES=("cloudflared.service" "gokapi.service" "bookmarks.service" "planning-poker.service")
for service in "${SERVICES[@]}"; do
    if [ -f "/etc/systemd/system/$service" ]; then
        check "Service file exists: $service" "ok"
        
        # Check if enabled
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            check "  → Enabled" "ok"
        else
            warn "  → Not enabled (won't start on boot)"
        fi
        
        # Check if running
        if systemctl is-active "$service" >/dev/null 2>&1; then
            check "  → Running" "ok"
        else
            warn "  → Not running"
        fi
        
        # Check restart policy
        if grep -q "Restart=always" "/etc/systemd/system/$service"; then
            check "  → Restart=always" "ok"
        elif grep -q "Restart=on-failure" "/etc/systemd/system/$service"; then
            warn "  → Restart=on-failure (should be 'always' for critical services)"
        fi
    else
        check "Service file exists: $service" "fail"
    fi
    echo ""
done

echo "2. Checking Health Check System..."
echo ""

# Check health check service
if [ -f "/etc/systemd/system/service-health-check.service" ]; then
    check "Health check service file exists" "ok"
    
    # Check symlink
    if [ -L "/usr/local/bin/health-check-and-restart.sh" ]; then
        check "  → Symlink exists" "ok"
    else
        warn "  → Symlink missing (run fix-health-check-service.sh)"
    fi
else
    check "Health check service file exists" "fail"
fi

# Check health check timer
if systemctl list-timers --all | grep -q "service-health-check.timer"; then
    check "Health check timer exists" "ok"
    
    if systemctl is-active service-health-check.timer >/dev/null 2>&1; then
        check "  → Timer is active" "ok"
    else
        warn "  → Timer is not active"
    fi
    
    if systemctl is-enabled service-health-check.timer >/dev/null 2>&1; then
        check "  → Timer is enabled" "ok"
    else
        warn "  → Timer is not enabled"
    fi
    
    # Check interval
    INTERVAL=$(systemctl show service-health-check.timer -p OnUnitActiveSec --value 2>/dev/null || echo "")
    if [ "$INTERVAL" = "2min" ] || [ "$INTERVAL" = "120s" ]; then
        check "  → Interval: 2 minutes" "ok"
    else
        warn "  → Interval: $INTERVAL (should be 2min)"
    fi
else
    check "Health check timer exists" "fail"
fi

echo ""
echo "3. Checking Health Check Script Configuration..."
echo ""

HEALTH_SCRIPT="/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/health-check-and-restart.sh"

if [ -f "$HEALTH_SCRIPT" ]; then
    check "Health check script exists" "ok"
    
    if [ -x "$HEALTH_SCRIPT" ]; then
        check "  → Script is executable" "ok"
    else
        warn "  → Script is not executable"
    fi
    
    # Check if monitoring all services
    if grep -q "planning-poker.service" "$HEALTH_SCRIPT"; then
        check "  → Monitors planning-poker.service" "ok"
    else
        warn "  → Missing planning-poker.service in monitoring"
    fi
    
    if grep -q "bookmarks.service" "$HEALTH_SCRIPT"; then
        check "  → Monitors bookmarks.service" "ok"
    else
        warn "  → Missing bookmarks.service in monitoring"
    fi
else
    check "Health check script exists" "fail"
fi

echo ""
echo "4. Checking Docker Containers..."
echo ""

CONTAINERS=("caddy" "goatcounter" "nextcloud-app" "uptime-kuma" "pihole" "documents-to-calendar")
for container in "${CONTAINERS[@]}"; do
    RESTART_POLICY=$(docker inspect "$container" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || echo "not-found")
    if [ "$RESTART_POLICY" = "always" ]; then
        check "$container: restart=always" "ok"
    elif [ "$RESTART_POLICY" = "not-found" ]; then
        warn "$container: container not found"
    else
        warn "$container: restart=$RESTART_POLICY (should be 'always')"
    fi
done

echo ""
echo "5. Checking Scripts..."
echo ""

IMPORTANT_SCRIPTS=(
    "scripts/health-check-and-restart.sh"
    "scripts/ensure-services-running.sh"
    "scripts/optimize-system.sh"
    "scripts/fix-cloudflared-restart.sh"
    "scripts/update-health-check-interval.sh"
)

for script in "${IMPORTANT_SCRIPTS[@]}"; do
    FULL_PATH="/home/goce/Desktop/Cursor projects/Pi-version-control/$script"
    if [ -f "$FULL_PATH" ]; then
        if [ -x "$FULL_PATH" ]; then
            check "$script: exists and executable" "ok"
        else
            warn "$script: exists but not executable"
        fi
    else
        check "$script: exists" "fail"
    fi
done

echo ""
echo "6. Checking Service Files Match Repository..."
echo ""

# Check cloudflared.service
if diff -q /etc/systemd/system/cloudflared.service "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/cloudflared.service" >/dev/null 2>&1; then
    check "cloudflared.service matches repo" "ok"
else
    warn "cloudflared.service differs from repo"
    echo "  → Run: sudo cp '/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/cloudflared.service' /etc/systemd/system/"
fi

# Check planning-poker.service
if [ -f "/etc/systemd/system/planning-poker.service" ]; then
    if diff -q /etc/systemd/system/planning-poker.service "/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/planning-poker.service" >/dev/null 2>&1; then
        check "planning-poker.service matches repo" "ok"
    else
        warn "planning-poker.service differs from repo"
        echo "  → Run: sudo cp '/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/planning-poker.service' /etc/systemd/system/"
    fi
else
    warn "planning-poker.service not installed"
    echo "  → Run: sudo cp '/home/goce/Desktop/Cursor projects/Pi-version-control/systemd/planning-poker.service' /etc/systemd/system/"
fi

echo ""
echo "7. Checking Bookmarks Service..."
echo ""

BOOKMARKS_FILE="/mnt/ssd/apps/bookmarks/secure_slack_bookmarks.py"
if [ -f "$BOOKMARKS_FILE" ]; then
    check "Bookmarks Flask app exists" "ok"
    
    if grep -q "@app.route(\"/\")" "$BOOKMARKS_FILE" || grep -q '@app.route("/")' "$BOOKMARKS_FILE"; then
        check "  → Health check route exists" "ok"
    else
        warn "  → Health check route missing"
    fi
else
    check "Bookmarks Flask app exists" "fail"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Everything is configured correctly."
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Found $WARNINGS warning(s)${NC}"
    echo ""
    echo "Configuration is mostly correct, but some improvements are recommended."
else
    echo -e "${RED}✗ Found $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Some critical issues need to be fixed."
fi

echo ""
echo "To fix issues, run:"
echo "  sudo bash '/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/optimize-system.sh'"
echo ""

