#!/bin/bash
###############################################################################
# Fix 502 Errors - External Access Down
# Run this when external access (phone/outside network) returns 502
# but local access works fine
###############################################################################

echo "=========================================="
echo "Fixing 502 External Access Issues"
echo "=========================================="
echo ""

# 1. Restart Caddy
echo "1. Restarting Caddy..."
cd /mnt/ssd/docker-projects/caddy || { echo "ERROR: Caddy directory not found!"; exit 1; }
docker compose restart caddy
sleep 5

# Check Caddy is running
if docker ps --format '{{.Names}}' | grep -q "^caddy$"; then
    echo "   ✅ Caddy restarted"
else
    echo "   ❌ Caddy failed to start"
    docker compose up -d caddy
    sleep 5
fi

# 2. Test Caddy locally
echo ""
echo "2. Testing Caddy locally..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200\|301\|302"; then
    echo "   ✅ Caddy responding locally"
else
    echo "   ❌ Caddy not responding locally"
    echo "   Checking Caddy logs..."
    docker logs caddy --tail 20
fi

# 3. Restart Cloudflare Tunnel
echo ""
echo "3. Restarting Cloudflare Tunnel..."
echo "   (This requires sudo password)"
sudo systemctl restart cloudflared.service
sleep 10

# Check tunnel status
if systemctl is-active --quiet cloudflared.service; then
    echo "   ✅ Cloudflare tunnel restarted"
else
    echo "   ❌ Cloudflare tunnel failed to start"
    systemctl status cloudflared.service --no-pager | head -10
fi

# 4. Check tunnel logs
echo ""
echo "4. Recent Cloudflare tunnel logs:"
journalctl -u cloudflared.service --since "1 minute ago" --no-pager | tail -10

# 5. Test external access (may take a moment to propagate)
echo ""
echo "5. Testing external access..."
echo "   (May take 30-60 seconds for DNS to propagate)"
for domain in gmojsoski.com tickets.gmojsoski.com poker.gmojsoski.com; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain" 2>&1 || echo "000")
    if [[ "$response" =~ ^(200|301|302|303)$ ]]; then
        echo "   ✅ $domain: $response OK"
    else
        echo "   ⏳ $domain: $response (may need more time)"
    fi
    sleep 2
done

echo ""
echo "=========================================="
echo "Fix Complete"
echo "=========================================="
echo ""
echo "If subdomains are still down after 1-2 minutes:"
echo "1. Check Caddy logs: docker logs caddy"
echo "2. Check tunnel logs: journalctl -u cloudflared.service -f"
echo "3. Verify Caddy config: docker exec caddy cat /etc/caddy/Caddyfile"
echo ""
