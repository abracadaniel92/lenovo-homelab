#!/bin/bash
###############################################################################
# Fix All Services - Comprehensive Service Recovery
# Run this when services are going up and down
###############################################################################

set -e

echo "=========================================="
echo "Comprehensive Service Recovery"
echo "=========================================="
echo ""

# 1. Increase UDP buffer sizes (fixes Cloudflare tunnel instability)
echo "1. Increasing UDP buffer sizes..."
sudo sysctl -w net.core.rmem_max=8388608 > /dev/null 2>&1 || echo "   ⚠️  Could not set rmem_max (may need manual sudo)"
sudo sysctl -w net.core.rmem_default=8388608 > /dev/null 2>&1 || echo "   ⚠️  Could not set rmem_default (may need manual sudo)"
echo "   ✅ UDP buffer sizes configured"

# 2. Start Docker if not running
echo ""
echo "2. Checking Docker..."
if ! systemctl is-active --quiet docker; then
    echo "   Starting Docker..."
    sudo systemctl start docker
    sleep 5
fi
echo "   ✅ Docker is running"

# 3. Wait for Docker to be ready
until docker ps > /dev/null 2>&1; do
    echo "   Waiting for Docker..."
    sleep 2
done

# 4. Start Caddy (CRITICAL - must be first)
echo ""
echo "3. Starting Caddy..."
cd /home/docker-projects/caddy || cd /mnt/ssd/docker-projects/caddy || { echo "   ❌ ERROR: Caddy directory not found!"; exit 1; }
docker compose up -d caddy
sleep 5

# Wait for Caddy to be healthy
until docker ps --format '{{.Names}}' | grep -q "^caddy$"; do
    echo "   Waiting for Caddy to start..."
    sleep 2
done
echo "   ✅ Caddy is running"

# 5. Start all Docker containers
echo ""
echo "4. Starting Docker containers..."
declare -a containers=(
    "/mnt/ssd/apps/nextcloud:db"
    "/mnt/ssd/apps/nextcloud:app"
    "/mnt/ssd/docker-projects/travelsync:app"
    "/mnt/ssd/docker-projects/goatcounter:goatcounter"
    "/mnt/ssd/docker-projects/uptime-kuma:uptime-kuma"
    "/mnt/ssd/docker-projects/kitchenowl:kitchenowl"
    "/mnt/ssd/docker-projects/jellyfin:jellyfin"
    "/mnt/ssd/docker-projects/vaultwarden:vaultwarden"
    "/mnt/ssd/docker-projects/homepage:homepage"
    "/mnt/ssd/docker-projects/pihole:pihole"
    "/mnt/ssd/docker-projects/kavita:kavita"
    "/mnt/ssd/docker-projects/memos:memos"
)

for container_spec in "${containers[@]}"; do
    IFS=':' read -r compose_dir service_name <<< "$container_spec"
    if [ -d "$compose_dir" ]; then
        cd "$compose_dir"
        docker compose up -d "$service_name" > /dev/null 2>&1 && echo "   ✅ Started: $service_name" || echo "   ⚠️  Failed: $service_name"
    else
        echo "   ⚠️  Directory not found: $compose_dir"
    fi
done

# 6. Start Cloudflare Tunnel (Docker)
echo ""
echo "5. Starting Cloudflare Tunnel (Docker)..."
cd /home/docker-projects/cloudflared || cd /mnt/ssd/docker-projects/cloudflared || { echo "   ⚠️  Cloudflared directory not found!"; }
if [ -d "$(pwd)" ]; then
    docker compose up -d > /dev/null 2>&1 && echo "   ✅ Cloudflare Tunnel started" || echo "   ⚠️  Cloudflare Tunnel failed"
    sleep 5
fi

# 7. Start systemd services
echo ""
echo "6. Starting systemd services..."
sudo systemctl start planning-poker.service > /dev/null 2>&1 && echo "   ✅ planning-poker.service" || echo "   ⚠️  planning-poker.service failed"
sudo systemctl start gokapi.service > /dev/null 2>&1 && echo "   ✅ gokapi.service" || echo "   ⚠️  gokapi.service failed"
sudo systemctl start bookmarks.service > /dev/null 2>&1 && echo "   ✅ bookmarks.service" || echo "   ⚠️  bookmarks.service failed"

sleep 5

# 8. Test local connectivity
echo ""
echo "7. Testing local connectivity..."
for domain in tickets.gmojsoski.com poker.gmojsoski.com cloud.gmojsoski.com shopping.gmojsoski.com jellyfin.gmojsoski.com; do
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: $domain" http://localhost:8080 --max-time 3 2>&1 || echo "000")
    if [[ "$code" =~ ^[23] ]]; then
        echo "   ✅ $domain: $code"
    else
        echo "   ❌ $domain: $code"
    fi
done

# 9. Show status
echo ""
echo "8. Service Status:"
echo "   Docker containers:"
docker ps --format "   {{.Names}}: {{.Status}}" | head -10
echo ""
echo "   Cloudflare Tunnel:"
docker ps --filter "name=cloudflared" --format "   {{.Names}}: {{.Status}}" 2>/dev/null || echo "   ⚠️  Not running"
echo ""
echo "   Systemd services:"
systemctl is-active planning-poker.service gokapi.service bookmarks.service 2>&1 | sed 's/^/   /'

echo ""
echo "=========================================="
echo "Recovery Complete"
echo "=========================================="
echo ""
echo "If services are still down:"
echo "1. Check logs: docker logs <container-name>"
echo "2. Check tunnel: cd /home/docker-projects/cloudflared && docker compose logs -f"
echo "3. Restart external access: bash \"$(dirname \"$0\")/fix-external-access.sh\""
echo ""

