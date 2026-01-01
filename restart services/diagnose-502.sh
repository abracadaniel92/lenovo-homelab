#!/bin/bash
###############################################################################
# Diagnose 502 Errors - Test connectivity and configuration
###############################################################################

set -e

echo "=========================================="
echo "502 Error Diagnosis"
echo "=========================================="
echo ""

# 1. Check if services are listening
echo "1. Checking if services are listening on expected ports..."
ports=(5000 8000 3000 8082 8088 8091 8092)
for port in "${ports[@]}"; do
    if ss -tlnp | grep -q ":$port "; then
        echo "   ✅ Port $port is listening"
    else
        echo "   ❌ Port $port is NOT listening"
    fi
done

# 2. Check Caddy configuration
echo ""
echo "2. Checking Caddy configuration..."
if docker exec caddy cat /etc/caddy/Caddyfile | grep -q "host.docker.internal"; then
    echo "   ✅ Caddyfile uses host.docker.internal"
else
    echo "   ❌ Caddyfile still uses 172.17.0.1"
fi

# 3. Test host.docker.internal resolution
echo ""
echo "3. Testing host.docker.internal resolution from Caddy container..."
if docker exec caddy getent hosts host.docker.internal > /dev/null 2>&1; then
    resolved=$(docker exec caddy getent hosts host.docker.internal | awk '{print $1}')
    echo "   ✅ host.docker.internal resolves to: $resolved"
else
    echo "   ❌ host.docker.internal does not resolve"
fi

# 4. Check Caddy logs for recent 502 errors
echo ""
echo "4. Recent 502 errors in Caddy logs:"
docker logs caddy --tail 50 2>&1 | grep -i "502\|connection refused\|dial tcp" | tail -5 || echo "   No recent 502 errors found"

# 5. Test local connectivity through Caddy
echo ""
echo "5. Testing local connectivity through Caddy (port 8080)..."
for domain in analytics.gmojsoski.com files.gmojsoski.com cloud.gmojsoski.com bookmarks.gmojsoski.com tickets.gmojsoski.com poker.gmojsoski.com; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $domain" http://localhost:8080 --max-time 3 2>&1 || echo "000")
    if [[ "$code" =~ ^[23] ]]; then
        echo "   ✅ $domain: $code"
    else
        echo "   ❌ $domain: $code"
    fi
done

# 6. Check if services are accessible from host
echo ""
echo "6. Testing direct service connectivity from host..."
for port in 5000 8000 3000 8082 8088 8091 8092; do
    if timeout 2 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        echo "   ✅ Port $port is accessible"
    else
        echo "   ❌ Port $port is NOT accessible"
    fi
done

# 7. Check Cloudflare tunnel status
echo ""
echo "7. Checking Cloudflare tunnel status..."
if systemctl is-active --quiet cloudflared.service; then
    echo "   ✅ cloudflared.service is running"
    echo "   Recent tunnel logs:"
    journalctl -u cloudflared.service -n 5 --no-pager 2>&1 | sed 's/^/      /' || echo "      No recent logs"
else
    echo "   ❌ cloudflared.service is NOT running"
fi

echo ""
echo "=========================================="
echo "Diagnosis Complete"
echo "=========================================="
echo ""
echo "If services show as listening but Caddy can't reach them:"
echo "1. Check firewall: sudo ufw status"
echo "2. Check if services bind to 0.0.0.0 (not just 127.0.0.1)"
echo "3. Restart Caddy: cd /mnt/ssd/docker-projects/caddy && docker compose restart caddy"
echo "4. Check service logs for errors"
echo ""


