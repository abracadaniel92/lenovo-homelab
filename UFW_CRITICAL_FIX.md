# UFW Firewall Critical Fix for Poker and Bookmarks

## Problem

After enabling UFW firewall, poker and bookmarks became inaccessible because:
- Caddy (running in Docker) cannot reach services on host ports 3000 and 5000
- UFW blocks all connections by default, including Docker-to-host communication

## Critical Fix Required

Run this immediately:

```bash
# Allow Docker network to access service ports
sudo ufw allow from 172.17.0.0/16 to any port 3000 comment 'Poker from Docker'
sudo ufw allow from 172.17.0.0/16 to any port 5000 comment 'Bookmarks from Docker'
sudo ufw allow from 172.17.0.0/16 to any port 8000 comment 'Travelsync from Docker'
sudo ufw allow from 172.17.0.0/16 to any port 8081 comment 'Nextcloud from Docker'
sudo ufw allow from 172.17.0.0/16 to any port 8088 comment 'GoatCounter from Docker'
sudo ufw allow from 172.17.0.0/16 to any port 8091 comment 'Gokapi from Docker'

# Restart Caddy to refresh connections
docker restart caddy
```

## Or Use the Script

```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/configure-ufw-for-services.sh"
```

## Why This is Needed

1. **Caddy runs in Docker** - It's on the Docker network (172.17.0.0/16)
2. **Services run on host** - Poker (3000), Bookmarks (5000) are on the host
3. **UFW blocks by default** - Needs explicit rules to allow Docker→Host communication
4. **External access** - Users access via Cloudflare tunnel, not directly (so external ports don't need to be open)

## Verify Fix

After running the commands:

```bash
# Check firewall rules
sudo ufw status | grep -E "3000|5000"

# Test services locally
curl http://localhost:3000
curl http://localhost:5000

# Test via Caddy
curl -I http://localhost:8080 -H "Host: poker.gmojsoski.com"
curl -I http://localhost:8080 -H "Host: bookmarks.gmojsoski.com"

# Test public access
curl -I https://poker.gmojsoski.com
curl -I https://bookmarks.gmojsoski.com
```

## Important Note About External Access

**Poker and bookmarks ARE accessible from different IPs** - they go through:
1. Cloudflare Tunnel (handles external access)
2. Caddy (routes to correct service)
3. Local services (poker on 3000, bookmarks on 5000)

The firewall rules only need to allow **Docker→Host** communication, not external→host, because Cloudflare tunnel handles external access.

## Current Status

- ✅ Services running locally
- ✅ Ports listening (3000, 5000)
- ❌ UFW blocking Docker access
- ⚠️ Need to add firewall rules

