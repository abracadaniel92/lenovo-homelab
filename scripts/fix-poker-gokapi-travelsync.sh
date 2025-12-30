#!/bin/bash
###############################################################################
# Fix Poker, Gokapi, and Travelsync Routing
# Updates Caddyfile and restarts services
###############################################################################

echo "=========================================="
echo "Fixing Poker, Gokapi, and Travelsync"
echo "=========================================="
echo ""

CADDYFILE_REPO="/home/goce/Desktop/Cursor projects/Pi-version-control/docker/caddy/Caddyfile"
CADDYFILE_DOCKER="/mnt/ssd/docker-projects/caddy/config/Caddyfile"

# Check if Caddyfile needs updating
if [ -f "$CADDYFILE_DOCKER" ]; then
    echo "1. Updating Caddyfile..."
    
    # Copy updated Caddyfile
    cp "$CADDYFILE_REPO" "$CADDYFILE_DOCKER"
    
    if [ $? -eq 0 ]; then
        echo "   ✓ Caddyfile updated"
    else
        echo "   ✗ Failed to update Caddyfile"
        exit 1
    fi
    
    # Reload Caddy
    echo ""
    echo "2. Reloading Caddy..."
    docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1
    
    if [ $? -eq 0 ]; then
        echo "   ✓ Caddy reloaded"
    else
        echo "   ⚠ Caddy reload failed, restarting container..."
        docker restart caddy
        sleep 3
    fi
else
    echo "⚠ Caddyfile not found at $CADDYFILE_DOCKER"
fi

echo ""
echo "3. Updating Cloudflare config..."
CLOUDFLARE_CONFIG="/home/goce/.cloudflared/config.yml"
CLOUDFLARE_REPO="/home/goce/Desktop/Cursor projects/Pi-version-control/cloudflare/config.yml"

if [ -f "$CLOUDFLARE_CONFIG" ]; then
    cp "$CLOUDFLARE_REPO" "$CLOUDFLARE_CONFIG"
    echo "   ✓ Cloudflare config updated"
    
    echo ""
    echo "4. Restarting Cloudflare tunnel..."
    sudo systemctl restart cloudflared.service
    sleep 2
    
    if systemctl is-active cloudflared.service >/dev/null 2>&1; then
        echo "   ✓ Cloudflare tunnel restarted"
    else
        echo "   ✗ Cloudflare tunnel failed to start"
    fi
else
    echo "⚠ Cloudflare config not found"
fi

echo ""
echo "5. Testing services..."
echo ""

# Test local services
echo "Testing local services:"
echo -n "  Poker (localhost:3000): "
if curl -s http://localhost:3000 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Gokapi (localhost:8091): "
if curl -s http://localhost:8091 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Travelsync (localhost:8000): "
if curl -s http://localhost:8000 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo ""
echo "Testing Caddy routing:"
echo -n "  Poker via Caddy: "
if curl -s http://localhost:8080 -H "Host: poker.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Gokapi via Caddy: "
if curl -s http://localhost:8080 -H "Host: files.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Travelsync via Caddy: "
if curl -s http://localhost:8080 -H "Host: travelsync.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
echo ""
echo "Services should now be accessible at:"
echo "  • https://poker.gmojsoski.com"
echo "  • https://files.gmojsoski.com"
echo "  • https://travelsync.gmojsoski.com"
echo ""
echo "Note: DNS propagation may take a few minutes."

