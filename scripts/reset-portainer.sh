#!/bin/bash
###############################################################################
# Reset Portainer - Removes all Portainer data and allows fresh setup
# WARNING: This will delete all Portainer settings, users, and configurations
###############################################################################

echo "=========================================="
echo "Portainer Reset Script"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will delete ALL Portainer data including:"
echo "   - Admin accounts"
echo "   - User settings"
echo "   - Environment configurations"
echo "   - All saved preferences"
echo ""

# Check for --yes flag for non-interactive use
if [ "$1" != "--yes" ]; then
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Reset cancelled."
        exit 0
    fi
else
    echo "Non-interactive mode: proceeding with reset..."
fi

PORTAINER_DIR="/mnt/ssd/docker-projects/portainer"

echo ""
echo "1. Stopping Portainer..."
cd "$PORTAINER_DIR" || exit 1
docker compose down

echo ""
echo "2. Removing Portainer data volume..."
docker volume rm portainer_portainer-data 2>/dev/null || docker volume rm portainer-data 2>/dev/null

if [ $? -eq 0 ]; then
    echo "   ✓ Data volume removed"
else
    echo "   ⚠️  Volume removal failed (may not exist)"
fi

echo ""
echo "3. Starting Portainer..."
docker compose up -d

echo ""
echo "4. Waiting for Portainer to start..."
sleep 5

echo ""
echo "5. Checking Portainer status..."
if docker ps | grep -q portainer; then
    echo "   ✓ Portainer is running!"
    echo ""
    echo "=========================================="
    echo "Portainer Reset Complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Open http://localhost:9000 in your browser"
    echo "  2. You'll see the setup screen"
    echo "  3. Create a new admin account:"
    echo "     - Username: (choose one)"
    echo "     - Password: (minimum 12 characters)"
    echo "  4. Select 'Docker' as your environment"
    echo "  5. Click 'Get Started'"
    echo ""
    echo "⚠️  Remember to save your new credentials!"
    echo ""
else
    echo "   ✗ Portainer failed to start"
    echo "   Check logs: docker logs portainer"
    exit 1
fi

