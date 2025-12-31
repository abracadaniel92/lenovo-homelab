# Cloudflare Tunnel - High Availability Setup

## Overview

This setup runs **2 cloudflared instances** for redundancy. If one crashes, the other continues serving traffic with zero downtime.

## How It Works

1. **Replicas**: Docker runs 2 identical cloudflared containers
2. **Load Balancing**: Cloudflare automatically load balances between them
3. **Failover**: If one dies, Cloudflare routes traffic to the surviving instance
4. **Auto-restart**: Docker restarts failed containers automatically

## Setup Instructions

### Step 1: Stop the existing systemd service

```bash
sudo systemctl stop cloudflared.service
sudo systemctl disable cloudflared.service
```

### Step 2: Start the Docker-based tunnel

```bash
cd /mnt/ssd/docker-projects/cloudflared
# Or copy files there first:
# sudo mkdir -p /mnt/ssd/docker-projects/cloudflared
# sudo cp docker-compose.yml /mnt/ssd/docker-projects/cloudflared/

docker compose up -d
```

### Step 3: Verify both replicas are running

```bash
docker compose ps
# Should show 2 containers running

docker compose logs -f
# Should show both connecting to Cloudflare
```

## Monitoring

### Check replica status
```bash
docker compose ps
```

### Check logs
```bash
docker compose logs --tail 50
```

### Check health
```bash
docker inspect cloudflared-ha-1 --format='{{.State.Health.Status}}'
docker inspect cloudflared-ha-2 --format='{{.State.Health.Status}}'
```

## Recovery

If both replicas are down:
```bash
cd /mnt/ssd/docker-projects/cloudflared
docker compose down
docker compose up -d
```

## Benefits

- **Zero downtime**: One replica can handle all traffic while the other restarts
- **Automatic failover**: Cloudflare handles routing automatically
- **Self-healing**: Docker restarts failed containers
- **Better stability**: UDP buffer settings applied per container

## Architecture

```
Internet
    ↓
Cloudflare Edge
    ↓
┌─────────────────────────────────┐
│  cloudflared replica 1          │──┐
│  (4 connections to CF)          │  │
└─────────────────────────────────┘  │
                                     ├─→ Caddy:8080 → Services
┌─────────────────────────────────┐  │
│  cloudflared replica 2          │──┘
│  (4 connections to CF)          │
└─────────────────────────────────┘
```

## Rollback

If you need to go back to systemd:

```bash
# Stop Docker tunnel
cd /mnt/ssd/docker-projects/cloudflared
docker compose down

# Re-enable systemd
sudo systemctl enable cloudflared.service
sudo systemctl start cloudflared.service
```

