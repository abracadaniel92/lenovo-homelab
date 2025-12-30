#!/bin/bash
###############################################################################
# Fix Cloudflare Tunnel - Comprehensive Troubleshooting and Fix Script
# Diagnoses and fixes common Cloudflare tunnel issues
###############################################################################

echo "=========================================="
echo "Cloudflare Tunnel Fix Script"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root for some operations
if [ "$EUID" -ne 0 ]; then 
    SUDO="sudo"
else
    SUDO=""
fi

# Step 1: Check current status
echo "1. Checking current status..."
echo ""

# Check cloudflared service
if systemctl is-active --quiet cloudflared.service; then
    echo -e "${GREEN}✓${NC} Cloudflared service is running"
else
    echo -e "${RED}✗${NC} Cloudflared service is NOT running"
    echo "   Starting cloudflared..."
    $SUDO systemctl start cloudflared.service
    sleep 5
fi

# Check Caddy
if docker ps | grep -q caddy; then
    echo -e "${GREEN}✓${NC} Caddy container is running"
else
    echo -e "${RED}✗${NC} Caddy container is NOT running"
    echo "   Starting Caddy..."
    cd /mnt/ssd/docker-projects/caddy && docker compose up -d
fi

# Test local connectivity
echo ""
echo "2. Testing local connectivity..."
LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: gmojsoski.com" http://localhost:8080 2>/dev/null)
if [ "$LOCAL_TEST" = "200" ]; then
    echo -e "${GREEN}✓${NC} Caddy responds correctly on localhost:8080"
else
    echo -e "${RED}✗${NC} Caddy returned: $LOCAL_TEST"
    echo "   This needs to be fixed first!"
    exit 1
fi

# Test public endpoint
echo ""
echo "3. Testing public endpoint..."
PUBLIC_TEST=$(curl -s -o /dev/null -w "%{http_code}" https://gmojsoski.com 2>/dev/null)
if [ "$PUBLIC_TEST" = "200" ]; then
    echo -e "${GREEN}✓${NC} Public endpoint is UP (Status: 200)"
    echo ""
    echo "Tunnel is working! No fix needed."
    exit 0
else
    echo -e "${YELLOW}⚠${NC} Public endpoint returned: $PUBLIC_TEST"
    echo "   Tunnel needs fixing..."
fi

echo ""
echo "=========================================="
echo "Applying Fixes"
echo "=========================================="
echo ""

# Fix 1: Restart cloudflared with proper wait
echo "Fix 1: Restarting cloudflared service..."
$SUDO systemctl stop cloudflared.service
sleep 3
$SUDO systemctl start cloudflared.service
echo "   Waiting for tunnel to establish connections..."
sleep 15

# Check if connections are established
CONNECTIONS=$(journalctl -u cloudflared.service --since "30 seconds ago" --no-pager | grep -c "Registered tunnel connection" || echo "0")
if [ "$CONNECTIONS" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Tunnel connections established: $CONNECTIONS"
else
    echo -e "${YELLOW}⚠${NC} No tunnel connections found yet (may need more time)"
fi

# Fix 2: Verify config file
echo ""
echo "Fix 2: Verifying configuration..."
CONFIG_FILE="/home/goce/.cloudflared/config.yml"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓${NC} Config file exists: $CONFIG_FILE"
    if grep -q "localhost:8080" "$CONFIG_FILE"; then
        echo -e "${GREEN}✓${NC} Config points to localhost:8080 (correct)"
    else
        echo -e "${RED}✗${NC} Config does not point to localhost:8080"
    fi
else
    echo -e "${RED}✗${NC} Config file not found: $CONFIG_FILE"
fi

# Fix 3: Check credentials
echo ""
echo "Fix 3: Verifying credentials..."
CRED_FILE="/home/goce/.cloudflared/df638884-0d3e-4799-8a98-60e844fcd164.json"
if [ -f "$CRED_FILE" ]; then
    echo -e "${GREEN}✓${NC} Credentials file exists"
else
    echo -e "${RED}✗${NC} Credentials file missing: $CRED_FILE"
    echo "   You may need to recreate the tunnel"
fi

# Fix 4: Test again after restart
echo ""
echo "Fix 4: Testing public endpoint again (waiting 10 seconds)..."
sleep 10
PUBLIC_TEST2=$(curl -s -o /dev/null -w "%{http_code}" https://gmojsoski.com 2>/dev/null)
if [ "$PUBLIC_TEST2" = "200" ]; then
    echo -e "${GREEN}✓${NC} SUCCESS! Public endpoint is now UP (Status: 200)"
    echo ""
    echo "Tunnel is working!"
    exit 0
else
    echo -e "${YELLOW}⚠${NC} Still returning: $PUBLIC_TEST2"
fi

echo ""
echo "=========================================="
echo "Additional Troubleshooting Steps"
echo "=========================================="
echo ""

# Check recent errors
echo "Recent errors in cloudflared logs:"
journalctl -u cloudflared.service --since "2 minutes ago" --no-pager | grep -i "error\|err" | tail -5 || echo "No recent errors"

echo ""
echo "If the tunnel is still not working, try:"
echo ""
echo "1. Check Cloudflare Dashboard:"
echo "   → Go to Zero Trust → Tunnels"
echo "   → Verify tunnel 'portfolio' is showing as 'Healthy'"
echo "   → Check for any errors or warnings"
echo ""
echo "2. Verify DNS in Cloudflare:"
echo "   → Go to DNS → Records"
echo "   → Ensure gmojsoski.com has a CNAME pointing to:"
echo "     <tunnel-id>.cfargotunnel.com"
echo "   → Or ensure it's using Cloudflare proxy (orange cloud)"
echo ""
echo "3. Test tunnel manually:"
echo "   cloudflared tunnel --config /home/goce/.cloudflared/config.yml run"
echo "   (Press Ctrl+C after testing)"
echo ""
echo "4. Recreate tunnel (if needed):"
echo "   → Delete old tunnel in Cloudflare dashboard"
echo "   → Run: cloudflared tunnel create portfolio"
echo "   → Update config.yml with new tunnel ID"
echo ""
echo "5. Check firewall/network:"
echo "   → Ensure port 8080 is accessible from localhost"
echo "   → Check if any firewall is blocking connections"
echo ""

# Check tunnel metrics
echo "Tunnel metrics (requests proxied):"
curl -s http://localhost:20241/metrics 2>/dev/null | grep "cloudflared_tunnel_total_requests" || echo "Metrics not available"

echo ""

