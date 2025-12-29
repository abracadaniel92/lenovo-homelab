# UFW Firewall Configuration Fix

**Issue**: After enabling UFW firewall, poker and bookmarks services became inaccessible.

## Problem

When UFW firewall is enabled, it blocks all incoming connections by default. While your services are running locally, the firewall may be blocking:
- Local service-to-service communication
- Docker network communication
- Caddy accessing local services

## Solution

Run the firewall configuration script:

```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/configure-ufw-for-services.sh"
```

Or manually configure:

```bash
# Allow SSH
sudo ufw allow 22/tcp
sudo ufw allow 222/tcp
sudo ufw allow 223/tcp

# Allow DNS
sudo ufw allow 53/udp

# Allow local service ports (from localhost only)
sudo ufw allow from 127.0.0.1 to any port 3000 comment 'Poker'
sudo ufw allow from 127.0.0.1 to any port 5000 comment 'Bookmarks'
sudo ufw allow from 127.0.0.1 to any port 8000 comment 'Travelsync'
sudo ufw allow from 127.0.0.1 to any port 8080 comment 'Caddy'
sudo ufw allow from 127.0.0.1 to any port 8081 comment 'Nextcloud'
sudo ufw allow from 127.0.0.1 to any port 8088 comment 'GoatCounter'
sudo ufw allow from 127.0.0.1 to any port 8091 comment 'Gokapi'

# Allow Docker networks
sudo ufw allow from 172.17.0.0/16 comment 'Docker bridge'
sudo ufw allow from 172.18.0.0/16 comment 'Docker networks'
```

## Verify

After configuration:

```bash
# Check firewall status
sudo ufw status verbose

# Test services locally
curl http://localhost:3000
curl http://localhost:5000

# Test via Caddy
curl -H "Host: poker.gmojsoski.com" http://localhost:8080
curl -H "Host: bookmarks.gmojsoski.com" http://localhost:8080
```

## Important Notes

1. **Services are behind Cloudflare**: External ports don't need to be open
2. **Local-only rules**: Services only need to accept connections from localhost
3. **Docker networks**: Need to allow Docker bridge network communication
4. **No external exposure**: All services accessed via Cloudflare tunnel

## Current Status

- ✅ Services are running locally
- ⚠️ Firewall may be blocking local communication
- ✅ Run configuration script to fix

