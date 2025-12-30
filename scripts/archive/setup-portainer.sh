#!/bin/bash
###############################################################################
# Setup Portainer - Docker Web UI
# Provides visual interface for managing Docker containers
###############################################################################

echo "=========================================="
echo "Setting up Portainer Docker UI"
echo "=========================================="
echo ""

# Create directory
PORTAINER_DIR="/mnt/ssd/docker-projects/portainer"
REPO_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control"

echo "1. Creating Portainer directory..."
mkdir -p "$PORTAINER_DIR"

echo "2. Copying docker-compose.yml..."
if [ -f "$REPO_DIR/docker/portainer/docker-compose.yml" ]; then
    cp "$REPO_DIR/docker/portainer/docker-compose.yml" "$PORTAINER_DIR/"
    echo "   ✓ docker-compose.yml copied"
else
    echo "   ✗ docker-compose.yml not found, creating default..."
    cat > "$PORTAINER_DIR/docker-compose.yml" <<EOF
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer-data:/data
    command: -H unix:///var/run/docker.sock

volumes:
  portainer-data:
EOF
    echo "   ✓ Default docker-compose.yml created"
fi

echo ""
echo "3. Starting Portainer..."
cd "$PORTAINER_DIR"
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
    echo "Portainer Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Access Portainer:"
    echo "  • Local HTTP:  http://localhost:9000"
    echo "  • Local HTTPS: https://localhost:9443"
    echo ""
    echo "First time setup:"
    echo "  1. Open http://localhost:9000 in your browser"
    echo "  2. Create an admin account"
    echo "  3. Select 'Docker' environment"
    echo "  4. Start managing your containers!"
    echo ""
    echo "To access via domain (optional):"
    echo "  1. Add route to Caddyfile (see DOCKER_UI_SETUP.md)"
    echo "  2. Add to Cloudflare config (see DOCKER_UI_SETUP.md)"
    echo ""
else
    echo "   ✗ Portainer failed to start"
    echo "   Check logs: docker logs portainer"
    exit 1
fi

