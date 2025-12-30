#!/bin/bash
###############################################################################
# Install FileBrowser - Web File Manager
# Manage files via web browser
###############################################################################

echo "=========================================="
echo "Installing FileBrowser"
echo "=========================================="
echo ""

FILEBROWSER_DIR="/mnt/ssd/docker-projects/filebrowser"

echo "1. Creating FileBrowser directory..."
mkdir -p "$FILEBROWSER_DIR/filebrowser-data"

echo "2. Creating docker-compose.yml..."
cat > "$FILEBROWSER_DIR/docker-compose.yml" <<EOF
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    restart: always
    ports:
      - "8082:80"
    volumes:
      - /mnt/ssd:/srv
      - ./filebrowser-data:/data
EOF

echo "3. Starting FileBrowser..."
cd "$FILEBROWSER_DIR"
docker compose up -d

echo ""
echo "4. Waiting for FileBrowser to start..."
sleep 5

if docker ps | grep -q filebrowser; then
    echo "   ✓ FileBrowser is running!"
    echo ""
    echo "=========================================="
    echo "FileBrowser Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Access FileBrowser:"
    echo "  • Local: http://localhost:8082"
    echo ""
    echo "Default credentials:"
    echo "  • Username: admin"
    echo "  • Password: admin"
    echo ""
    echo "⚠️  IMPORTANT: Change password after first login!"
    echo ""
    echo "Next steps:"
    echo "  1. Open http://localhost:8082"
    echo "  2. Login with admin/admin"
    echo "  3. Go to Settings → Change password"
    echo ""
else
    echo "   ✗ FileBrowser failed to start"
    echo "   Check logs: docker logs filebrowser"
    exit 1
fi

