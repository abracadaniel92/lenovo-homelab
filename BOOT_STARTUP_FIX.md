# Boot Startup Order Fix

## Problem

When the machine restarted, services were starting in random order, causing:
- **200+ Kuma alerts** due to services being down during boot
- **Downtime** because dependencies weren't ready
- **Cloudflared** trying to connect before Caddy was ready
- **Planning Poker** starting before network was fully up

## Solution

Created a proper startup sequence that ensures services start in the correct order.

## What Was Fixed

### 1. Docker Containers Startup Service
- **Service**: `docker-containers-start.service`
- **Script**: `/usr/local/bin/start-docker-containers.sh`
- **Startup Order**:
  1. **Caddy** (reverse proxy - needed by everything)
  2. **Nextcloud database** (database must be ready before app)
  3. **Application services** (Nextcloud app, TravelSync)
  4. **Other services** (GoatCounter, Uptime Kuma, Pi-hole)

### 2. Systemd Service Dependencies Updated

**Planning Poker Service:**
- Now waits for: `network-online.target`, `docker.service`, `docker-containers-start.service`
- Ensures network and Docker containers are ready before starting

**Cloudflared Service:**
- Now waits for: `docker-containers-start.service`
- Ensures Caddy is ready before trying to connect

**Other Services:**
- Gokapi and Bookmarks wait for `network-online.target`

## Boot Sequence

On system restart, services now start in this order:

1. **Docker service** starts
2. **Network** comes online
3. **docker-containers-start.service** runs:
   - Starts Caddy and waits for it to be ready
   - Starts Nextcloud database
   - Starts application services
   - Starts other services
4. **Planning Poker** starts (after Docker containers are ready)
5. **Cloudflared** starts (after Docker containers are ready)
6. **Other systemd services** start (Gokapi, Bookmarks)

## Verification

To verify the configuration:

```bash
# Check if startup service is enabled
systemctl is-enabled docker-containers-start.service

# Check service dependencies
systemctl show planning-poker.service | grep After
systemctl show cloudflared.service | grep After

# View startup script
cat /usr/local/bin/start-docker-containers.sh
```

## Testing

To manually test the startup sequence:

```bash
# Start the Docker containers in order
sudo systemctl start docker-containers-start.service

# View logs
journalctl -u docker-containers-start.service -f

# Check status
systemctl status docker-containers-start.service
```

## Result

- ✅ Services start in proper order
- ✅ Dependencies are ready before services start
- ✅ Minimal downtime on boot
- ✅ Kuma alerts only for real problems, not boot issues

## Files Created/Modified

- `/etc/systemd/system/docker-containers-start.service` - New service
- `/usr/local/bin/start-docker-containers.sh` - Startup script
- `/etc/systemd/system/planning-poker.service` - Updated dependencies
- `/etc/systemd/system/cloudflared.service` - Updated dependencies
- `/etc/systemd/system/gokapi.service` - Updated dependencies (if exists)
- `/etc/systemd/system/bookmarks.service` - Updated dependencies (if exists)

## Maintenance

The startup service runs automatically on boot. No manual intervention needed.

If you need to restart all containers in order:
```bash
sudo systemctl restart docker-containers-start.service
```

