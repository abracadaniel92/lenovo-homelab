#!/bin/bash
###############################################################################
# Fix Homepage Host Validation Error
# Creates proper config file to fix host validation
###############################################################################

echo "=========================================="
echo "Fixing Homepage Host Validation"
echo "=========================================="
echo ""

HOMEPAGE_DIR="/mnt/ssd/docker-projects/homepage"
CONFIG_DIR="$HOMEPAGE_DIR/config"

echo "1. Creating config directory..."
mkdir -p "$CONFIG_DIR"

echo "2. Creating settings.yaml..."
cat > "$CONFIG_DIR/settings.yaml" <<EOF
# Homepage Settings
# This file fixes host validation errors

# Allow all hosts (for local development)
# Remove this if you want to restrict access
hostname: '*'

# Or specify allowed hosts:
# hostname:
#   - localhost
#   - 127.0.0.1
#   - your-domain.com
EOF

echo "3. Creating basic services.yaml..."
cat > "$CONFIG_DIR/services.yaml" <<EOF
# Homepage Services Configuration
# Add your services here

- Services:
    - Portainer:
        href: http://localhost:9000
        description: Docker management
        icon: simple-icons:portainer
    - Uptime Kuma:
        href: http://localhost:3001
        description: Service monitoring
        icon: simple-icons:uptimekuma
EOF

echo "4. Setting proper permissions..."
chmod -R 755 "$CONFIG_DIR"

echo "5. Restarting Homepage..."
cd "$HOMEPAGE_DIR"
docker compose restart

echo ""
echo "6. Waiting for Homepage to restart..."
sleep 5

echo ""
echo "=========================================="
echo "Fix Applied!"
echo "=========================================="
echo ""
echo "Try accessing Homepage again:"
echo "  http://localhost:3002"
echo ""
echo "If still having issues, check logs:"
echo "  docker logs homepage --tail 50"
echo ""
echo "The settings.yaml file allows all hosts."
echo "You can customize it later in:"
echo "  $CONFIG_DIR/settings.yaml"
echo ""

