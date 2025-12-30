#!/bin/bash
###############################################################################
# Fix UFW Firewall - Allow Docker Access to Host Services
# CRITICAL: This fixes poker, bookmarks, and gokapi being inaccessible
###############################################################################

echo "=========================================="
echo "Fixing UFW Firewall for Docker Access"
echo "=========================================="
echo ""

if ! command -v ufw &> /dev/null; then
    echo "✗ UFW is not installed"
    exit 1
fi

echo "1. Adding critical firewall rules for Docker→Host access..."
echo ""

# CRITICAL: Allow Docker network (172.17.0.0/16) to access host services
# This is needed because Caddy (in Docker) must reach services on host

echo "   → Allowing Docker to access Poker (port 3000)..."
sudo ufw allow from 172.17.0.0/16 to any port 3000 comment 'Poker from Docker' 2>/dev/null || echo "     (rule may already exist)"

echo "   → Allowing Docker to access Bookmarks (port 5000)..."
sudo ufw allow from 172.17.0.0/16 to any port 5000 comment 'Bookmarks from Docker' 2>/dev/null || echo "     (rule may already exist)"

echo "   → Allowing Docker to access Gokapi (port 8091)..."
sudo ufw allow from 172.17.0.0/16 to any port 8091 comment 'Gokapi from Docker' 2>/dev/null || echo "     (rule may already exist)"

echo "   → Allowing Docker to access Travelsync (port 8000)..."
sudo ufw allow from 172.17.0.0/16 to any port 8000 comment 'Travelsync from Docker' 2>/dev/null || echo "     (rule may already exist)"

echo "   → Allowing Docker to access Nextcloud (port 8081)..."
sudo ufw allow from 172.17.0.0/16 to any port 8081 comment 'Nextcloud from Docker' 2>/dev/null || echo "     (rule may already exist)"

echo "   → Allowing Docker to access GoatCounter (port 8088)..."
sudo ufw allow from 172.17.0.0/16 to any port 8088 comment 'GoatCounter from Docker' 2>/dev/null || echo "     (rule may already exist)"

echo ""
echo "2. Allowing localhost access (for testing)..."
sudo ufw allow from 127.0.0.1 to any port 3000 comment 'Poker localhost' 2>/dev/null || true
sudo ufw allow from 127.0.0.1 to any port 5000 comment 'Bookmarks localhost' 2>/dev/null || true
sudo ufw allow from 127.0.0.1 to any port 8091 comment 'Gokapi localhost' 2>/dev/null || true

echo ""
echo "3. Reloading firewall..."
sudo ufw reload

echo ""
echo "4. Restarting Caddy to refresh connections..."
docker restart caddy
sleep 3

echo ""
echo "5. Testing services..."
echo ""

# Test local access
echo "Testing local access:"
echo -n "  Poker (localhost:3000): "
if curl -s --max-time 2 http://localhost:3000 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Bookmarks (localhost:5000): "
if curl -s --max-time 2 http://localhost:5000 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo -n "  Gokapi (localhost:8091): "
if curl -s --max-time 2 http://localhost:8091 >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗"
fi

echo ""
echo "Testing via Caddy:"
echo -n "  Poker via Caddy: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: poker.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ (check Caddy logs: docker logs caddy --tail 10)"
fi

echo -n "  Bookmarks via Caddy: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: bookmarks.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ (check Caddy logs: docker logs caddy --tail 10)"
fi

echo -n "  Gokapi via Caddy: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: files.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ (check Caddy logs: docker logs caddy --tail 10)"
fi

echo ""
echo "6. Current firewall rules for these ports:"
sudo ufw status | grep -E "3000|5000|8091" || echo "  (no rules found - this is the problem!)"

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
echo ""
echo "If services are still not accessible:"
echo "  1. Check firewall: sudo ufw status verbose"
echo "  2. Check Caddy logs: docker logs caddy --tail 20"
echo "  3. Check services: systemctl status planning-poker.service gokapi.service bookmarks.service"
echo ""

