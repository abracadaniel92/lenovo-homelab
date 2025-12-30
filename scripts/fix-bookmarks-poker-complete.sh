#!/bin/bash
###############################################################################
# Complete Fix for Bookmarks and Poker Services
# Fixes both services based on Pi-version-control configuration
###############################################################################

echo "=========================================="
echo "Fixing Bookmarks and Poker Services"
echo "=========================================="
echo ""

# Fix 1: Add health check route to Bookmarks Flask app
echo "1. Fixing Bookmarks Service..."
echo ""

BOOKMARKS_FILE="/mnt/ssd/apps/bookmarks/secure_slack_bookmarks.py"

if [ -f "$BOOKMARKS_FILE" ]; then
    # Check if health route exists
    if ! grep -q "@app.route(\"/\")" "$BOOKMARKS_FILE" && ! grep -q "@app.route('/')" "$BOOKMARKS_FILE"; then
        echo "   Adding health check route to Flask app..."
        
        # Backup original
        cp "$BOOKMARKS_FILE" "${BOOKMARKS_FILE}.backup"
        
        # Add health check route before the bookmark route
        sed -i '/@app.route("\/bookmark"/i@app.route("/")\ndef index():\n    return jsonify({"status": "ok", "service": "bookmarks"}), 200\n\n' "$BOOKMARKS_FILE"
        
        echo "   ✓ Added health check route"
        echo "   Restarting bookmarks service..."
        sudo systemctl restart bookmarks.service
        sleep 3
        
        # Test
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null)
        if [ "$RESPONSE" = "200" ]; then
            echo "   ✓ Bookmarks service is now responding correctly"
        else
            echo "   ⚠ Response code: $RESPONSE (may need more time)"
        fi
    else
        echo "   ✓ Health check route already exists"
        echo "   Restarting service..."
        sudo systemctl restart bookmarks.service
    fi
else
    echo "   ✗ Bookmarks file not found: $BOOKMARKS_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Fixing Poker Service"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

POKER_DIR="/home/goce/Desktop/Cursor projects/planning poker/planning_poker"
POKER_SERVICE="/etc/systemd/system/planning-poker.service"

# Check if service exists
if [ -f "$POKER_SERVICE" ]; then
    echo "   ✓ Planning poker systemd service exists"
    if systemctl is-active --quiet planning-poker.service; then
        echo "   ✓ Service is running"
    else
        echo "   Starting service..."
        sudo systemctl start planning-poker.service
        sleep 3
        if systemctl is-active --quiet planning-poker.service; then
            echo "   ✓ Service started successfully"
        else
            echo "   ✗ Failed to start service"
            sudo systemctl status planning-poker.service --no-pager | head -10
        fi
    fi
else
    echo "   Creating systemd service for planning poker..."
    
    # Check if poker directory exists
    if [ ! -d "$POKER_DIR" ]; then
        echo "   ✗ Poker directory not found: $POKER_DIR"
        exit 1
    fi
    
    # Check if node is available
    if ! command -v node > /dev/null 2>&1; then
        echo "   ✗ Node.js not found. Install with: sudo apt install nodejs npm"
        exit 1
    fi
    
    # Create systemd service
    sudo tee "$POKER_SERVICE" > /dev/null << EOF
[Unit]
Description=Planning Poker Service
After=network.target

[Service]
Type=simple
User=goce
WorkingDirectory=$POKER_DIR
ExecStart=$(which node) server.js
Restart=always
RestartSec=10
Environment="PORT=3000"
Environment="HOST_PASSWORD=admin123"
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
EOF
    
    echo "   ✓ Created systemd service"
    sudo systemctl daemon-reload
    sudo systemctl enable planning-poker.service
    sudo systemctl start planning-poker.service
    
    sleep 3
    if systemctl is-active --quiet planning-poker.service; then
        echo "   ✓ Service started successfully"
    else
        echo "   ✗ Failed to start service"
        sudo systemctl status planning-poker.service --no-pager | head -10
    fi
fi

# Test poker
echo ""
echo "   Testing poker service..."
sleep 2
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
if [ "$RESPONSE" = "200" ]; then
    echo "   ✓ Poker service is responding correctly"
else
    echo "   ⚠ Response code: $RESPONSE"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""

# Test both services
echo "Testing services..."
echo ""

BOOKMARKS_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/ 2>/dev/null)
POKER_TEST=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)

echo "Bookmarks (localhost:5000): $BOOKMARKS_TEST"
if [ "$BOOKMARKS_TEST" = "200" ]; then
    echo "  ✓ Working"
else
    echo "  ✗ Not working"
fi

echo "Poker (localhost:3000): $POKER_TEST"
if [ "$POKER_TEST" = "200" ]; then
    echo "  ✓ Working"
else
    echo "  ✗ Not working"
fi

echo ""
echo "Test public endpoints:"
echo "  curl -I https://bookmarks.gmojsoski.com"
echo "  curl -I https://poker.gmojsoski.com"
echo ""

