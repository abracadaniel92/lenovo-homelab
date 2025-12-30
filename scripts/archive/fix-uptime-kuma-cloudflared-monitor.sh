#!/bin/bash
###############################################################################
# Fix Uptime Kuma Cloudflared Monitor Configuration
# Helps diagnose and fix false "down" alerts
###############################################################################

echo "=========================================="
echo "Diagnosing Uptime Kuma Cloudflared Monitor"
echo "=========================================="
echo ""

# Check if the public endpoint is actually accessible
echo "1. Testing public endpoint (https://gmojsoski.com)..."
PUBLIC_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://gmojsoski.com 2>/dev/null)
echo "   Status Code: $PUBLIC_STATUS"

if [ "$PUBLIC_STATUS" = "200" ]; then
    echo "   ✓ Public endpoint is UP"
elif [ "$PUBLIC_STATUS" = "502" ]; then
    echo "   ✗ Public endpoint returns 502 Bad Gateway"
    echo "   → This means Cloudflare tunnel is not forwarding properly"
    echo "   → Uptime Kuma is correctly detecting it as DOWN"
    echo ""
    echo "   Fix: Restart cloudflared service"
    echo "   sudo systemctl restart cloudflared.service"
elif [ "$PUBLIC_STATUS" = "000" ] || [ -z "$PUBLIC_STATUS" ]; then
    echo "   ✗ Cannot reach public endpoint"
    echo "   → Check network connectivity"
else
    echo "   ⚠ Status Code: $PUBLIC_STATUS"
fi
echo ""

# Check local services
echo "2. Checking local services..."
if systemctl is-active --quiet cloudflared.service; then
    echo "   ✓ Cloudflared service is running"
else
    echo "   ✗ Cloudflared service is NOT running"
    echo "   → Fix: sudo systemctl start cloudflared.service"
fi

if docker ps | grep -q caddy; then
    echo "   ✓ Caddy container is running"
else
    echo "   ✗ Caddy container is NOT running"
    echo "   → Fix: cd /mnt/ssd/docker-projects/caddy && docker compose up -d"
fi
echo ""

# Check local Caddy
echo "3. Testing local Caddy (localhost:8080)..."
LOCAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: gmojsoski.com" http://localhost:8080 2>/dev/null)
if [ "$LOCAL_STATUS" = "200" ]; then
    echo "   ✓ Local Caddy is responding correctly"
else
    echo "   ✗ Local Caddy returned: $LOCAL_STATUS"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

if [ "$PUBLIC_STATUS" != "200" ] && systemctl is-active --quiet cloudflared.service && docker ps | grep -q caddy; then
    echo "⚠️  ISSUE: Services are running but public endpoint is down"
    echo ""
    echo "This means the Cloudflare tunnel is not properly forwarding requests."
    echo ""
    echo "Try these fixes:"
    echo "  1. Restart cloudflared:"
    echo "     sudo systemctl restart cloudflared.service"
    echo ""
    echo "  2. Check cloudflared logs:"
    echo "     journalctl -u cloudflared.service -n 50"
    echo ""
    echo "  3. Verify tunnel is connected:"
    echo "     journalctl -u cloudflared.service | grep -i 'registered tunnel connection'"
    echo ""
    echo "  4. Check Cloudflare dashboard for tunnel status"
    echo ""
elif [ "$PUBLIC_STATUS" = "200" ]; then
    echo "✓ Public endpoint is UP"
    echo ""
    echo "If Uptime Kuma still shows it as down, check:"
    echo "  1. Monitor configuration in Uptime Kuma:"
    echo "     - URL should be: https://gmojsoski.com"
    echo "     - Expected Status Code: 200"
    echo "     - Keyword (if using): Should match text on your site"
    echo ""
    echo "  2. Check Uptime Kuma logs:"
    echo "     docker logs uptime-kuma --tail 50"
    echo ""
    echo "  3. Test the monitor manually in Uptime Kuma UI"
fi
echo ""

