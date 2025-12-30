#!/bin/bash
###############################################################################
# Quick Fix All Services - Run from Phone/SSH
# One command to fix all common service issues
###############################################################################

echo "=========================================="
echo "Quick Fix All Services"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check service
check_service() {
    local name=$1
    local url=$2
    local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" --max-time 3 2>&1)
    if [ "$status" = "200" ] || [ "$status" = "302" ] || [ "$status" = "303" ] || [ "$status" = "301" ]; then
        echo -e "${GREEN}✅ $name: OK ($status)${NC}"
        return 0
    else
        echo -e "${RED}❌ $name: FAILED ($status)${NC}"
        return 1
    fi
}

# 1. Check Docker
echo "1. Checking Docker..."
if ! systemctl is-active --quiet docker; then
    echo -e "${YELLOW}⚠️  Docker not running, starting...${NC}"
    sudo systemctl start docker
    sleep 3
fi

# Wait for Docker
until docker ps > /dev/null 2>&1; do
    echo "Waiting for Docker..."
    sleep 2
done
echo -e "${GREEN}✅ Docker is ready${NC}"

# 2. Restart Caddy (critical - reverse proxy)
echo ""
echo "2. Restarting Caddy..."
cd /mnt/ssd/docker-projects/caddy
docker compose restart caddy
sleep 3
check_service "Caddy" "http://localhost:8080/"

# 3. Restart Cloudflare Tunnel
echo ""
echo "3. Restarting Cloudflare Tunnel..."
sudo systemctl restart cloudflared.service
sleep 5
if systemctl is-active --quiet cloudflared.service; then
    echo -e "${GREEN}✅ Cloudflare Tunnel: Running${NC}"
else
    echo -e "${RED}❌ Cloudflare Tunnel: Failed${NC}"
fi

# 4. Restart TravelSync
echo ""
echo "4. Restarting TravelSync..."
cd /mnt/ssd/docker-projects/documents-to-calendar
docker compose restart
sleep 3
check_service "TravelSync" "http://localhost:8000/api/health"

# 5. Restart Planning Poker
echo ""
echo "5. Restarting Planning Poker..."
sudo systemctl restart planning-poker.service
sleep 2
check_service "Planning Poker" "http://localhost:3000/"

# 6. Restart Nextcloud
echo ""
echo "6. Restarting Nextcloud..."
cd /mnt/ssd/apps/nextcloud
docker compose restart app
sleep 3
check_service "Nextcloud" "http://localhost:8081/"

# 7. Restart other services
echo ""
echo "7. Restarting other services..."
sudo systemctl restart gokapi.service
sudo systemctl restart bookmarks.service
sleep 2

# 8. Restart other Docker services
echo ""
echo "8. Restarting other Docker services..."
cd /mnt/ssd/docker-projects/goatcounter && docker compose restart &
cd /mnt/ssd/docker-projects/uptime-kuma && docker compose restart &
wait
sleep 3

# 9. Final status check
echo ""
echo "=========================================="
echo "Final Status Check"
echo "=========================================="
echo ""

check_service "Caddy" "http://localhost:8080/"
check_service "TravelSync" "http://localhost:8000/api/health"
check_service "Planning Poker" "http://localhost:3000/"
check_service "Nextcloud" "http://localhost:8081/"
check_service "GoatCounter" "http://localhost:8088/"
check_service "Gokapi" "http://localhost:8091/"
check_service "Uptime Kuma" "http://localhost:3001/"
check_service "Bookmarks" "http://localhost:5000/"

echo ""
echo "Systemd Services:"
systemctl is-active cloudflared.service > /dev/null && echo -e "${GREEN}✅ cloudflared${NC}" || echo -e "${RED}❌ cloudflared${NC}"
systemctl is-active planning-poker.service > /dev/null && echo -e "${GREEN}✅ planning-poker${NC}" || echo -e "${RED}❌ planning-poker${NC}"
systemctl is-active gokapi.service > /dev/null && echo -e "${GREEN}✅ gokapi${NC}" || echo -e "${RED}❌ gokapi${NC}"
systemctl is-active bookmarks.service > /dev/null && echo -e "${GREEN}✅ bookmarks${NC}" || echo -e "${RED}❌ bookmarks${NC}"

echo ""
echo "=========================================="
echo "Quick Fix Complete!"
echo "=========================================="
echo ""
echo "External access may take 30-60 seconds to update."
echo "Test: curl -I https://tickets.gmojsoski.com"
echo ""

