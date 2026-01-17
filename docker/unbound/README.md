# Unbound DNS Recursive Resolver

Unbound is a recursive DNS resolver that queries root DNS servers directly, providing better privacy and potentially faster responses through caching.

## Purpose

- **Privacy**: No upstream DNS provider (Cloudflare, Google, etc.) sees your DNS queries
- **Performance**: Recursive caching can improve response times for repeated queries
- **Independence**: No dependency on external DNS providers

## How It Works

1. Pi-hole forwards DNS queries to Unbound (port 5335)
2. Unbound recursively resolves queries by querying root DNS servers
3. Results are cached for faster future lookups
4. Pi-hole filters ads and provides local DNS records as usual

## Network Architecture

```
Client → Pi-hole (port 53) → Unbound (127.0.0.1:5335) → Root DNS Servers
```

- Pi-hole: Listens on port 53 (host network)
- Unbound: Listens on port 5335 (host network, localhost only)
- No port conflicts: Unbound uses 5335, Pi-hole uses 53

## Configuration

### docker-compose.yml
- Uses `network_mode: host` so Pi-hole can reach it via `127.0.0.1`
- Mounts `unbound.conf` as read-only config file

### unbound.conf
- Listens on `127.0.0.1:5335` (localhost only, port 5335)
- Disables IPv6 (can be enabled if needed)
- Optimized for Raspberry Pi 4 (2 threads, cache settings)
- Privacy features enabled (hides version, identity)

## Installation

1. **Start Unbound**:
   ```bash
   cd /path/to/repo/docker/unbound
   docker compose up -d
   ```

2. **Verify Unbound is running**:
   ```bash
   docker ps | grep unbound
   docker logs unbound
   ```

3. **Test Unbound directly**:
   ```bash
   dig @127.0.0.1 -p 5335 google.com
   ```

4. **Update Pi-hole configuration**:
   - Pi-hole `docker-compose.yml` should have: `PIHOLE_DNS_: '127.0.0.1#5335'`
   - Restart Pi-hole: `docker restart pihole`

5. **Verify Pi-hole is using Unbound**:
   - Check Pi-hole logs: `docker logs pihole | grep -i unbound`
   - Or check Pi-hole Admin UI → Settings → DNS → Upstream DNS Servers

## Troubleshooting

### Unbound won't start
```bash
# Check logs
docker logs unbound

# Verify config file syntax
docker exec unbound unbound-checkconf
```

### Pi-hole can't reach Unbound
- Ensure Unbound is running: `docker ps | grep unbound`
- Test connectivity: `dig @127.0.0.1 -p 5335 google.com`
- Check Pi-hole DNS setting: Should be `127.0.0.1#5335`
- Verify both containers use `network_mode: host`

### DNS queries are slow
- First-time queries may be slower (recursive lookup)
- Subsequent queries should be faster (cached)
- Check cache stats: `docker exec unbound unbound-control stats`

### Revert to Cloudflare DNS
Change Pi-hole `PIHOLE_DNS_` back to `'1.1.1.1;1.0.0.1'` and restart Pi-hole.

## Resource Usage

- **RAM**: ~50-150MB
- **CPU**: Minimal (increases during recursive queries)
- **Disk**: Minimal (cached DNS records)

Pi 4 with 4GB RAM can easily handle both Pi-hole and Unbound.

