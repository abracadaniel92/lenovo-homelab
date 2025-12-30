#!/bin/bash
###############################################################################
# Complete External Access Fix
# Run this when external access is completely down
###############################################################################

set -e

echo "=========================================="
echo "Complete External Access Fix"
echo "=========================================="
echo ""

# 1. Stop Cloudflare Tunnel
echo "1. Stopping Cloudflare Tunnel..."
sudo systemctl stop cloudflared.service
sleep 3

# 2. Restart Caddy
echo "2. Restarting Caddy..."
cd /mnt/ssd/docker-projects/caddy || { echo "ERROR: Caddy directory not found!"; exit 1; }
docker compose restart caddy
sleep 5

# Verify Caddy is running
if ! docker ps --format '{{.Names}}' | grep -q "^caddy$"; then
    echo "   ❌ Caddy failed to start, trying to start it..."
    docker compose up -d caddy
    sleep 5
fi

# 3. Test Caddy locally
echo ""
echo "3. Testing Caddy locally..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 | grep -q "200\|301\|302"; then
    echo "   ✅ Caddy responding on 127.0.0.1:8080"
else
    echo "   ❌ Caddy NOT responding on 127.0.0.1:8080"
    echo "   Checking Caddy logs..."
    docker logs caddy --tail 30
    exit 1
fi

# 4. Start Cloudflare Tunnel
echo ""
echo "4. Starting Cloudflare Tunnel..."
sudo systemctl start cloudflared.service
sleep 10

# Check tunnel status
if systemctl is-active --quiet cloudflared.service; then
    echo "   ✅ Cloudflare tunnel started"
else
    echo "   ❌ Cloudflare tunnel failed to start"
    systemctl status cloudflared.service --no-pager | head -15
    exit 1
fi

# 5. Wait for tunnel connections
echo ""
echo "5. Waiting for tunnel connections to establish..."
sleep 15

# Check for registered connections
connections=$(journalctl -u cloudflared.service --since "30 seconds ago" --no-pager | grep -c "Registered tunnel connection" || echo "0")
if [ "$connections" -gt 0 ]; then
    echo "   ✅ Tunnel connections established ($connections connections)"
else
    echo "   ⚠️  No tunnel connections found yet (may need more time)"
fi

# 6. Test external access
echo ""
echo "6. Testing external access..."
echo "   (May take 30-60 seconds for DNS to propagate)"
for domain in tickets.gmojsoski.com poker.gmojsoski.com cloud.gmojsoski.com; do
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$domain" 2>&1 || echo "000")
    if [[ "$response" =~ ^(200|301|302|303)$ ]]; then
        echo "   ✅ $domain: $response OK"
    else
        echo "   ⏳ $domain: $response (may need more time or check logs)"
    fi
    sleep 2
done

echo ""
echo "=========================================="
echo "Fix Complete"
echo "=========================================="
echo ""
echo "If external access is still down:"
echo "1. Check Caddy logs: docker logs caddy"
echo "2. Check tunnel logs: journalctl -u cloudflared.service -f"
echo "3. Verify tunnel config: cat ~/.cloudflared/config.yml"
echo "4. Wait 1-2 minutes for DNS propagation"
echo ""
