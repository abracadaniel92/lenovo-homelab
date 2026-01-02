#!/bin/bash
###############################################################################
# Fix External Access - Restore External Service Access
# Run this when external services are down (502/404 errors)
###############################################################################

set -e

echo "=========================================="
echo "Fixing External Access"
echo "=========================================="
echo ""

# 1. Restart Caddy (reverse proxy)
echo "1. Restarting Caddy..."
cd /home/docker-projects/caddy || cd /mnt/ssd/docker-projects/caddy || { echo "❌ ERROR: Caddy directory not found!"; exit 1; }
docker compose restart caddy
sleep 5

# Verify Caddy is running
if ! docker ps --format '{{.Names}}' | grep -q "^caddy$"; then
    echo "   ❌ Caddy failed to start, trying to start it..."
    docker compose up -d caddy
    sleep 5
fi

if docker ps --format '{{.Names}}' | grep -q "^caddy$"; then
    echo "   ✅ Caddy is running"
else
    echo "   ❌ Caddy failed to start"
    echo "   Checking logs..."
    docker logs caddy --tail 20
    exit 1
fi

# 2. Test Caddy locally
echo ""
echo "2. Testing Caddy locally..."
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 --max-time 3 | grep -qE "200|301|302"; then
    echo "   ✅ Caddy responding on 127.0.0.1:8080"
else
    echo "   ⚠️  Caddy not responding as expected, but continuing..."
fi

# 3. Restart Cloudflare Tunnel (Docker)
echo ""
echo "3. Restarting Cloudflare Tunnel (Docker)..."
cd /home/docker-projects/cloudflared || cd /mnt/ssd/docker-projects/cloudflared || { echo "❌ ERROR: Cloudflared directory not found!"; exit 1; }
docker compose restart
sleep 10

# Check tunnel status
TUNNEL_COUNT=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" 2>/dev/null | wc -l)
if [ "$TUNNEL_COUNT" -ge 1 ]; then
    echo "   ✅ Cloudflare tunnel restarted ($TUNNEL_COUNT replica(s) running)"
else
    echo "   ❌ Cloudflare tunnel failed to start, trying to start..."
    docker compose up -d
    sleep 10
    TUNNEL_COUNT=$(docker ps --filter "name=cloudflared" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$TUNNEL_COUNT" -ge 1 ]; then
        echo "   ✅ Cloudflare tunnel started ($TUNNEL_COUNT replica(s))"
    else
        echo "   ❌ Cloudflare tunnel failed to start"
        docker compose logs --tail 30
        exit 1
    fi
fi

# 4. Wait for tunnel connections
echo ""
echo "4. Waiting for tunnel connections to establish..."
sleep 15

# 5. Check tunnel logs
echo ""
echo "5. Recent Cloudflare tunnel logs:"
docker compose logs --tail 10 | grep -E "connection|registered|error|failed" | tail -5 || docker compose logs --tail 5

# 6. Test external access (may take a moment)
echo ""
echo "6. Testing external access..."
echo "   (May take 30-60 seconds for connections to establish)"
for domain in gmojsoski.com jellyfin.gmojsoski.com; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain" --max-time 10 2>&1 || echo "000")
    if [[ "$code" =~ ^[23] ]]; then
        echo "   ✅ $domain: HTTP $code"
    else
        echo "   ⚠️  $domain: HTTP $code (may need more time)"
    fi
done

echo ""
echo "=========================================="
echo "Fix Complete"
echo "=========================================="
echo ""
echo "If services are still down:"
echo "1. Wait 1-2 minutes for tunnel connections to fully establish"
echo "2. Check logs: cd /home/docker-projects/cloudflared && docker compose logs -f"
echo "3. Restart tunnel: cd /home/docker-projects/cloudflared && docker compose restart"
echo ""

