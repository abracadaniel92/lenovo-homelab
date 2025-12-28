#!/bin/bash
###############################################################################
# Install Homepage - Service Dashboard
# Beautiful dashboard for all your services
###############################################################################

echo "=========================================="
echo "Installing Homepage Dashboard"
echo "=========================================="
echo ""

HOMEPAGE_DIR="/mnt/ssd/docker-projects/homepage"

echo "1. Creating Homepage directory..."
mkdir -p "$HOMEPAGE_DIR/config"

echo "2. Creating settings.yaml to fix host validation..."
cat > "$HOMEPAGE_DIR/config/settings.yaml" <<EOF
# Homepage Settings
# Allow all hosts to fix validation error
hostname: '*'
EOF

echo "2. Creating docker-compose.yml..."
cat > "$HOMEPAGE_DIR/docker-compose.yml" <<EOF
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: always
    ports:
      - "3002:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - HOMEPAGE_ALLOWED_HOSTS=*
EOF

echo "3. Starting Homepage..."
cd "$HOMEPAGE_DIR"
docker compose up -d

echo ""
echo "4. Waiting for Homepage to start..."
sleep 5

if docker ps | grep -q homepage; then
    echo "   ✓ Homepage is running!"
    echo ""
    echo "=========================================="
    echo "Homepage Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Access Homepage:"
    echo "  • Local: http://localhost:3002"
    echo ""
    echo "Next steps:"
    echo "  1. Open http://localhost:3002"
    echo "  2. Configure services in config directory"
    echo "  3. See documentation: https://gethomepage.dev/"
    echo ""
else
    echo "   ✗ Homepage failed to start"
    echo "   Check logs: docker logs homepage"
    exit 1
fi

