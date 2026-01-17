# Setting Up Unbound on Raspberry Pi

## Step 1: Find or Clone the Repository

**Option A: If repo is already on your Pi, find it:**
```bash
# Search for the repo
find ~ -name "Pi-version-control" -type d 2>/dev/null
# Or search for pihole docker-compose
find ~ -name "pihole" -path "*/docker/pihole" -type d 2>/dev/null
```

**Option B: Clone the repo if you haven't:**
```bash
cd ~
git clone https://github.com/abracadaniel92/lenovo-homelab.git Pi-version-control
cd Pi-version-control/Pi-version-control
```

## Step 2: Navigate to Unbound Directory

```bash
# Adjust the path based on where you found/cloned the repo
cd /path/to/Pi-version-control/Pi-version-control/docker/unbound

# Verify files are there
ls -la
# Should show: docker-compose.yml, unbound.conf, README.md
```

## Step 3: Start Unbound

```bash
docker compose up -d
```

## Step 4: Verify Unbound is Running

```bash
# Check container status
docker ps | grep unbound

# Check logs
docker logs unbound

# Test Unbound directly
dig @127.0.0.1 -p 5335 google.com
```

## Step 5: Restart Pi-hole to Use Unbound

```bash
docker restart pihole
```

## Step 6: Verify Pi-hole is Using Unbound

Check Pi-hole Admin UI:
- Go to: Settings → DNS → Upstream DNS Servers
- Should show: `127.0.0.1#5335`

Or check Pi-hole logs:
```bash
docker logs pihole | grep -i "using upstream"
```

## Troubleshooting

### "No configuration file provided" error

This means the config file isn't being found. Check:
1. You're in the correct directory: `cd docker/unbound`
2. `unbound.conf` file exists: `ls -la unbound.conf`
3. Try running with full path:
   ```bash
   docker compose -f /full/path/to/docker/unbound/docker-compose.yml up -d
   ```

### Unbound won't start

Check logs:
```bash
docker logs unbound
```

Common issues:
- Config file syntax error: Check `unbound.conf` format
- Port already in use: Check `sudo ss -tulpn | grep 5335`
- Permission issues: Ensure user can run docker commands

### Pi-hole can't reach Unbound

Ensure both use `network_mode: host` and Unbound is listening on `127.0.0.1:5335`.

Test connectivity:
```bash
dig @127.0.0.1 -p 5335 google.com
```

