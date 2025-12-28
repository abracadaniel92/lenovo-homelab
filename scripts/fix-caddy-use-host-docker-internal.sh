#!/bin/bash
###############################################################################
# Fix Caddy to use host.docker.internal instead of 172.17.0.1
# This bypasses UFW blocking issues
###############################################################################

echo "=========================================="
echo "Fixing Caddy to use host.docker.internal"
echo "=========================================="
echo ""

CADDYFILE="/home/goce/Desktop/Cursor projects/Pi-version-control/docker/caddy/Caddyfile"

if [ ! -f "$CADDYFILE" ]; then
    echo "✗ Caddyfile not found: $CADDYFILE"
    exit 1
fi

echo "1. Creating backup of Caddyfile..."
cp "$CADDYFILE" "${CADDYFILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "2. Updating Caddyfile to use host.docker.internal..."
echo ""

# Replace 172.17.0.1 with host.docker.internal
sed -i 's|http://172\.17\.0\.1:|http://host.docker.internal:|g' "$CADDYFILE"

echo "   ✓ Updated all reverse_proxy targets"

echo ""
echo "3. Verifying changes..."
echo ""
grep -n "host.docker.internal" "$CADDYFILE" | head -10

echo ""
echo "4. Reloading Caddy configuration..."
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1 || {
    echo "   → Reload failed, restarting container..."
    docker restart caddy
    sleep 3
}

echo ""
echo "5. Testing services..."
echo ""

sleep 2

echo -n "  Poker: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: poker.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Bookmarks: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: bookmarks.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Gokapi: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: files.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
echo ""
echo "If services are still not accessible, check:"
echo "  docker logs caddy --tail 20"
echo ""

