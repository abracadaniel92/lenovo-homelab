# Home Assistant Setup

Home Assistant is configured to run **locally only**. It is not exposed through Caddy or Cloudflare Tunnel.

## Quick Start

```bash
# Navigate to Home Assistant directory
cd /home/docker-projects/homeassistant

# Start Home Assistant
docker compose --profile utilities up -d

# View logs
docker compose logs -f

# Access Home Assistant
# Open browser: http://localhost:8123
# Or from another device on your network: http://<server-ip>:8123
```

## Configuration

- **Port**: 8123 (standard Home Assistant port)
- **Network Mode**: Host (for better device discovery)
- **Resource Limits**: 2GB RAM, 1 CPU
- **Profile**: `utilities` (use `--profile utilities` to start)
- **Config Directory**: `./config` (persists across restarts)

## First Run

1. Start the container: `docker compose --profile utilities up -d`
2. Wait 2-3 minutes for initial setup
3. Access at `http://localhost:8123` or `http://<server-ip>:8123`
4. Create your admin account
5. Start adding integrations for your devices

## Device Access

The container runs with:
- **Privileged mode**: Required for some device integrations
- **Host networking**: Better device discovery on local network
- **Device access**: USB serial devices (`/dev/ttyUSB0`, `/dev/ttyACM0`, `/dev/ttyAMA0`)

## Notes

- **Local Only**: Not exposed externally (no Caddy/Cloudflare config)
- **Future**: Can be exposed later if needed by adding to Caddyfile

## Stopping

```bash
# Stop Home Assistant
docker compose stop

# Stop and remove container (keeps config)
docker compose down
```

## Backup

The `config/` directory contains all your Home Assistant configuration. Back it up regularly:

```bash
# Backup Home Assistant config
tar -czf homeassistant-backup-$(date +%Y%m%d).tar.gz config/
```

