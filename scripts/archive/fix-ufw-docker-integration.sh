#!/bin/bash
###############################################################################
# Fix UFW + Docker Integration
# CRITICAL: UFW blocks Docker containers by default
# This script configures UFW to work properly with Docker
###############################################################################

echo "=========================================="
echo "Fixing UFW + Docker Integration"
echo "=========================================="
echo ""

if ! command -v ufw &> /dev/null; then
    echo "✗ UFW is not installed"
    exit 1
fi

echo "1. Configuring UFW to work with Docker..."
echo ""

# UFW needs special configuration to allow Docker containers
# We need to modify UFW's before.rules to allow Docker's iptables rules

UFW_BEFORE_RULES="/etc/ufw/before.rules"

echo "   → Checking UFW before.rules for Docker configuration..."

# Check if Docker rules already exist
if grep -q "# Docker rules" "$UFW_BEFORE_RULES" 2>/dev/null; then
    echo "     Docker rules already configured"
else
    echo "     Adding Docker rules to UFW before.rules..."
    
    # Create backup
    sudo cp "$UFW_BEFORE_RULES" "${UFW_BEFORE_RULES}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add Docker rules before the COMMIT line
    sudo sed -i '/^COMMIT$/i\
# Docker rules\
# Allow Docker containers to access host services\
-A ufw-before-input -i docker0 -j ACCEPT\
-A ufw-before-output -o docker0 -j ACCEPT\
' "$UFW_BEFORE_RULES"
    
    echo "     ✓ Docker rules added"
fi

echo ""
echo "2. Adding explicit firewall rules for service ports..."
echo ""

# Add rules to allow Docker network to access host services
echo "   → Adding rules for Docker→Host access..."

sudo ufw allow from 172.17.0.0/16 to any port 3000 comment 'Poker from Docker' 2>&1 | grep -v "Skipping" || true
sudo ufw allow from 172.17.0.0/16 to any port 5000 comment 'Bookmarks from Docker' 2>&1 | grep -v "Skipping" || true
sudo ufw allow from 172.17.0.0/16 to any port 8091 comment 'Gokapi from Docker' 2>&1 | grep -v "Skipping" || true
sudo ufw allow from 172.17.0.0/16 to any port 8000 comment 'Travelsync from Docker' 2>&1 | grep -v "Skipping" || true
sudo ufw allow from 172.17.0.0/16 to any port 8081 comment 'Nextcloud from Docker' 2>&1 | grep -v "Skipping" || true
sudo ufw allow from 172.17.0.0/16 to any port 8088 comment 'GoatCounter from Docker' 2>&1 | grep -v "Skipping" || true

echo ""
echo "3. Reloading UFW..."
sudo ufw reload

echo ""
echo "4. Restarting Docker to refresh iptables rules..."
sudo systemctl restart docker
sleep 2

echo ""
echo "5. Restarting Caddy..."
docker restart caddy
sleep 3

echo ""
echo "6. Testing connectivity..."
echo ""

# Test local services
echo "Local service tests:"
for port in 3000 5000 8091; do
    echo -n "  Port $port: "
    if timeout 2 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        echo "✓ Listening"
    else
        echo "✗ Not accessible"
    fi
done

echo ""
echo "Caddy proxy tests:"
echo -n "  Poker: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: poker.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ (check: docker logs caddy --tail 5)"
fi

echo -n "  Bookmarks: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: bookmarks.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ (check: docker logs caddy --tail 5)"
fi

echo -n "  Gokapi: "
if curl -s --max-time 3 http://localhost:8080 -H "Host: files.gmojsoski.com" >/dev/null 2>&1; then
    echo "✓"
else
    echo "✗ (check: docker logs caddy --tail 5)"
fi

echo ""
echo "7. Current firewall status:"
echo ""
sudo ufw status | grep -E "3000|5000|8091|172.17" | head -10 || echo "  (no matching rules found)"

echo ""
echo "=========================================="
echo "Fix Complete!"
echo "=========================================="
echo ""
echo "If services are still not accessible:"
echo "  1. Check UFW before.rules: sudo cat /etc/ufw/before.rules | grep -A5 Docker"
echo "  2. Check Caddy logs: docker logs caddy --tail 20"
echo "  3. Check iptables: sudo iptables -L -n -v | grep docker0"
echo "  4. Try disabling UFW temporarily to test: sudo ufw disable"
echo ""

