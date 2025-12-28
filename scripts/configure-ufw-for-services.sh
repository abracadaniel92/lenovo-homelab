#!/bin/bash
###############################################################################
# Configure UFW Firewall for All Services
# Allows necessary ports for local services
###############################################################################

echo "=========================================="
echo "Configuring UFW Firewall for Services"
echo "=========================================="
echo ""

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
    echo "✗ UFW is not installed"
    echo "Install with: sudo apt install ufw"
    exit 1
fi

echo "1. Allowing SSH ports..."
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 222/tcp comment 'SSH alternate'
sudo ufw allow 223/tcp comment 'SSH alternate'

echo "2. Allowing DNS (Pi-hole)..."
sudo ufw allow 53/udp comment 'Pi-hole DNS'

echo "3. Allowing local service ports..."
# These are for local communication between services
# Services are accessed via Caddy (8080) which is behind Cloudflare tunnel
sudo ufw allow from 127.0.0.1 to any port 3000 comment 'Poker (local)'
sudo ufw allow from 127.0.0.1 to any port 5000 comment 'Bookmarks (local)'
sudo ufw allow from 127.0.0.1 to any port 8000 comment 'Travelsync (local)'
sudo ufw allow from 127.0.0.1 to any port 8080 comment 'Caddy (local)'
sudo ufw allow from 127.0.0.1 to any port 8081 comment 'Nextcloud (local)'
sudo ufw allow from 127.0.0.1 to any port 8088 comment 'GoatCounter (local)'
sudo ufw allow from 127.0.0.1 to any port 8091 comment 'Gokapi (local)'

echo "4. Allowing Docker network communication..."
# Allow Docker bridge network
sudo ufw allow from 172.17.0.0/16 comment 'Docker bridge network'
sudo ufw allow from 172.18.0.0/16 comment 'Docker networks'

echo ""
echo "5. Current firewall status:"
sudo ufw status numbered

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "Note: Services are accessed via Cloudflare tunnel, so external"
echo "ports don't need to be open. These rules allow local communication."
echo ""
echo "To check status: sudo ufw status verbose"
echo "To reload: sudo ufw reload"

