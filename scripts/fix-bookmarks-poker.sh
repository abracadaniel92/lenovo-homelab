#!/bin/bash
###############################################################################
# Fix Bookmarks and Poker Services
# Diagnoses and fixes issues with bookmarks.gmojsoski.com and poker.gmojsoski.com
###############################################################################

echo "=========================================="
echo "Diagnosing Bookmarks and Poker Services"
echo "=========================================="
echo ""

# Check Bookmarks
echo "1. Checking Bookmarks Service..."
echo ""

if systemctl is-active --quiet bookmarks.service; then
    echo "   ✓ Bookmarks service is running"
    PORT_5000=$(ss -tlnp | grep ":5000" || echo "")
    if [ -n "$PORT_5000" ]; then
        echo "   ✓ Port 5000 is listening"
    else
        echo "   ✗ Port 5000 is NOT listening"
    fi
    
    # Test the service
    echo ""
    echo "   Testing bookmarks service..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null)
    echo "   Response code: $RESPONSE"
    
    if [ "$RESPONSE" = "200" ] || [ "$RESPONSE" = "302" ]; then
        echo "   ✓ Service is responding correctly"
    else
        echo "   ✗ Service returned: $RESPONSE"
        echo ""
        echo "   Issue: Bookmarks service is running but returning 404"
        echo "   Possible causes:"
        echo "     - Flask app route configuration issue"
        echo "     - Service needs to be restarted"
        echo "     - Wrong path being accessed"
        echo ""
        echo "   Fix: Restart bookmarks service"
        echo "   sudo systemctl restart bookmarks.service"
    fi
else
    echo "   ✗ Bookmarks service is NOT running"
    echo "   Fix: sudo systemctl start bookmarks.service"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking Poker/Planning Poker Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if poker is running
POKER_PROCESS=$(ps aux | grep -E "node.*poker|planning.*poker" | grep -v grep || echo "")
PORT_3000=$(ss -tlnp | grep ":3000" || echo "")

if [ -n "$POKER_PROCESS" ]; then
    echo "   ✓ Planning poker process is running"
    echo "   $POKER_PROCESS"
elif [ -n "$PORT_3000" ]; then
    echo "   ⚠ Port 3000 is listening but process not found in ps"
else
    echo "   ✗ Planning poker is NOT running"
    echo "   ✗ Port 3000 is NOT listening"
fi

# Check if Caddy has route for poker
echo ""
echo "   Checking Caddy configuration..."
if docker exec caddy cat /etc/caddy/Caddyfile 2>/dev/null | grep -q "poker.gmojsoski.com"; then
    echo "   ✓ Caddy has route for poker.gmojsoski.com"
else
    echo "   ✗ Caddy does NOT have route for poker.gmojsoski.com"
    echo ""
    echo "   ISSUE: Caddy config is missing poker route!"
    echo ""
    echo "   Fix: Add to Caddyfile:"
    echo "   @poker host poker.gmojsoski.com"
    echo "   handle @poker {"
    echo "       encode gzip"
    echo "       reverse_proxy http://172.17.0.1:3000 {"
    echo "           header_up X-Forwarded-Proto https"
    echo "           header_up X-Real-IP {remote_host}"
    echo "       }"
    echo "   }"
fi

# Check if poker directory exists
if [ -d "/home/goce/Desktop/Cursor projects/planning poker/planning_poker" ]; then
    echo "   ✓ Planning poker directory exists"
    if [ -f "/home/goce/Desktop/Cursor projects/planning poker/planning_poker/server.js" ]; then
        echo "   ✓ server.js exists"
    fi
else
    echo "   ✗ Planning poker directory not found"
fi

echo ""
echo "=========================================="
echo "Summary & Fixes"
echo "=========================================="
echo ""

echo "BOOKMARKS:"
if systemctl is-active --quiet bookmarks.service; then
    echo "  Status: Running but may need restart"
    echo "  Action: sudo systemctl restart bookmarks.service"
else
    echo "  Status: Not running"
    echo "  Action: sudo systemctl start bookmarks.service"
fi

echo ""
echo "POKER:"
if [ -z "$POKER_PROCESS" ] && [ -z "$PORT_3000" ]; then
    echo "  Status: Not running"
    echo "  Actions needed:"
    echo "    1. Start planning poker service"
    echo "    2. Add route to Caddy config"
    echo ""
    echo "  To start poker:"
    echo "    cd '/home/goce/Desktop/Cursor projects/planning poker/planning_poker'"
    echo "    pm2 start ecosystem.config.js"
    echo "    # OR if using node directly:"
    echo "    node server.js"
    echo ""
    echo "  Then add to Caddyfile and reload Caddy"
else
    echo "  Status: Check Caddy configuration"
    echo "  Action: Add poker route to Caddyfile if missing"
fi

echo ""

