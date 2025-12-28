#!/bin/bash
###############################################################################
# Fix Poker Service Firewall Issue
# Allows Caddy to reach poker service on port 3000
###############################################################################

echo "=========================================="
echo "Fixing Poker Service Firewall Access"
echo "=========================================="
echo ""

# Check if ufw is active
if ! sudo ufw status | grep -q "Status: active"; then
    echo "⚠ UFW is not active, but continuing..."
fi

echo "1. Allowing port 3000 from Docker network..."
# Allow Caddy (running in Docker) to access port 3000 on host
sudo ufw allow from 172.17.0.0/16 to any port 3000 comment 'Poker from Docker'

echo "2. Allowing port 3000 from localhost..."
# Allow localhost access
sudo ufw allow from 127.0.0.1 to any port 3000 comment 'Poker localhost'

echo "3. Testing connection..."
sleep 1

# Test if Caddy can reach poker
if docker exec caddy curl -s --connect-timeout 2 http://172.17.0.1:3000 >/dev/null 2>&1; then
    echo "✓ Caddy can reach poker service"
else
    echo "⚠ Caddy still cannot reach poker - checking firewall rules..."
    sudo ufw status | grep 3000
fi

echo ""
echo "4. Restarting Caddy to refresh connections..."
docker restart caddy
sleep 3

echo ""
echo "5. Testing via Caddy..."
if curl -s --max-time 5 http://localhost:8080 -H "Host: poker.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓ Poker accessible via Caddy"
else
    echo "✗ Still having issues - check Caddy logs: docker logs caddy --tail 20"
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
echo ""
echo "If still not working, check:"
echo "  1. Firewall rules: sudo ufw status | grep 3000"
echo "  2. Poker service: systemctl status planning-poker.service"
echo "  3. Caddy logs: docker logs caddy --tail 30"
echo "  4. Test direct: curl http://localhost:3000"
echo ""

