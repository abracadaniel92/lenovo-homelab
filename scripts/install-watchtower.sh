#!/bin/bash
###############################################################################
# Install Watchtower - Auto-Update Docker Containers
# Automatically updates containers to latest versions
###############################################################################

echo "=========================================="
echo "Installing Watchtower (Auto-Updates)"
echo "=========================================="
echo ""

WATCHTOWER_DIR="/mnt/ssd/docker-projects/watchtower"

echo "1. Creating Watchtower directory..."
mkdir -p "$WATCHTOWER_DIR"

echo "2. Creating docker-compose.yml..."
cat > "$WATCHTOWER_DIR/docker-compose.yml" <<EOF
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *
      - WATCHTOWER_INCLUDE_STOPPED=true
      - WATCHTOWER_REVIVE_STOPPED=false
EOF

echo "3. Starting Watchtower..."
cd "$WATCHTOWER_DIR"
docker compose up -d

echo ""
echo "4. Waiting for Watchtower to start..."
sleep 3

if docker ps | grep -q watchtower; then
    echo "   ✓ Watchtower is running!"
    echo ""
    echo "=========================================="
    echo "Watchtower Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Watchtower will:"
    echo "  • Check for updates daily at 2 AM"
    echo "  • Auto-update containers"
    echo "  • Clean up old images"
    echo ""
    echo "View logs: docker logs watchtower"
    echo "Manual update check: docker restart watchtower"
    echo ""
else
    echo "   ✗ Watchtower failed to start"
    echo "   Check logs: docker logs watchtower"
    exit 1
fi

