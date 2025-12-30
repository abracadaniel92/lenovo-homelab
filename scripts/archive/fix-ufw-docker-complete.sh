#!/bin/bash
###############################################################################
# Complete UFW + Docker Fix
# Configures UFW to not interfere with Docker's iptables
###############################################################################

echo "=========================================="
echo "Complete UFW + Docker Fix"
echo "=========================================="
echo ""

if ! command -v ufw &> /dev/null; then
    echo "✗ UFW is not installed"
    exit 1
fi

echo "1. Configuring UFW to work with Docker..."
echo ""

# Set UFW to allow forwarding (needed for Docker)
sudo sed -i 's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

# Configure UFW before.rules to allow Docker
UFW_BEFORE_RULES="/etc/ufw/before.rules"

if ! grep -q "# Docker rules" "$UFW_BEFORE_RULES" 2>/dev/null; then
    echo "   → Adding Docker rules to before.rules..."
    sudo sed -i '/^COMMIT$/i\
# Docker rules\
-A ufw-before-input -i docker0 -j ACCEPT\
-A ufw-before-output -o docker0 -j ACCEPT\
-A ufw-before-forward -i docker0 -j ACCEPT\
-A ufw-before-forward -o docker0 -j ACCEPT\
' "$UFW_BEFORE_RULES"
    echo "   ✓ Docker rules added"
else
    echo "   ✓ Docker rules already exist"
fi

echo ""
echo "2. Disabling UFW management of Docker's iptables chains..."
echo ""

# Create/edit Docker daemon config to prevent UFW from managing Docker chains
DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

if [ ! -f "$DOCKER_DAEMON_JSON" ]; then
    echo "   → Creating Docker daemon.json..."
    echo '{"iptables": false}' | sudo tee "$DOCKER_DAEMON_JSON" > /dev/null
    echo "   ✓ Created daemon.json with iptables: false"
    echo "   ⚠️  WARNING: This disables Docker's automatic iptables management"
    echo "   ⚠️  You'll need to manually manage iptables or use a different approach"
else
    echo "   → Checking existing Docker daemon.json..."
    if grep -q '"iptables"' "$DOCKER_DAEMON_JSON"; then
        echo "   ✓ iptables setting already exists"
    else
        echo "   → Adding iptables: false to daemon.json..."
        # This is complex, so we'll suggest manual edit
        echo "   ⚠️  Please manually edit $DOCKER_DAEMON_JSON"
        echo "   ⚠️  Add: \"iptables\": false"
    fi
fi

echo ""
echo "3. Alternative: Temporarily disable UFW to test..."
echo ""
echo "   If you want to test without UFW:"
echo "   sudo ufw disable"
echo "   docker restart caddy"
echo "   # Test services..."
echo "   # If they work, UFW is the problem"
echo ""

echo "4. Reloading UFW..."
sudo ufw reload

echo ""
echo "5. Restarting Docker (if daemon.json was modified)..."
if [ -f "$DOCKER_DAEMON_JSON" ] && grep -q '"iptables": false' "$DOCKER_DAEMON_JSON"; then
    echo "   → Restarting Docker daemon..."
    sudo systemctl restart docker
    sleep 3
    echo "   → Restarting Caddy..."
    docker restart caddy
    sleep 3
else
    echo "   → Restarting Caddy only..."
    docker restart caddy
    sleep 3
fi

echo ""
echo "6. Testing services..."
echo ""

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
echo "Fix Applied!"
echo "=========================================="
echo ""
echo "If services are still not accessible, try:"
echo "  1. Temporarily disable UFW: sudo ufw disable"
echo "  2. Test services: curl -I http://localhost:8080 -H 'Host: poker.gmojsoski.com'"
echo "  3. If they work, UFW is blocking. Consider:"
echo "     - Removing UFW: sudo apt remove ufw"
echo "     - Or using iptables directly instead of UFW"
echo "     - Or configuring UFW more carefully"
echo ""

