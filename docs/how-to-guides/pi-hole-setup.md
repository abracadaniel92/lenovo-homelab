# Pi-hole Setup on Raspberry Pi 4

## Hardware
- **Model**: Raspberry Pi 4 Model B
- **RAM**: 4GB
- **Network**: Gigabit Ethernet (primary), WiFi (secondary)

## Network Configuration
- **Raspberry Pi 4 IP:** `[REDACTED_INTERNAL_IP_2]` (configure via router DHCP reservation)
- **lemongrab (main server) IP:** `[REDACTED_INTERNAL_IP_1]` (ThinkCentre IP)

## Purpose
Pi-hole provides:
- Network-wide ad blocking
- Local DNS resolution for `*.gmojsoski.com` → lemongrab (fixes NAT hairpinning)
- DNS query logging and statistics

---

## Step 1: Install Docker (if not already installed)

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add current user to docker group
sudo usermod -aG docker $USER

# Apply group changes (or log out and back in)
newgrp docker

# Verify Docker is working
docker --version
```

---

## Step 2: Create Pi-hole Directory

```bash
mkdir -p ~/pihole
cd ~/pihole
```

---

## Step 3: Create docker-compose.yml

The docker-compose.yml file is located in this repository at `docker/pihole/docker-compose.yml`.

**Key Configuration:**
- Uses `network_mode: host` for direct DNS access (ports 53, 80)
- Docker volumes for data persistence (not bind mounts)
- Timezone: `Europe/Skopje` (update if needed)
- Upstream DNS: Cloudflare (`1.1.1.1`, `1.0.0.1`)

**Important:** Update the following before starting:
1. `WEBPASSWORD`: Set a secure password for the admin interface
2. `FTLCONF_LOCAL_IPV4`: Set to your Pi's IP address

```bash
cd /path/to/repo/docker/pihole
# Edit docker-compose.yml and update WEBPASSWORD and FTLCONF_LOCAL_IPV4
nano docker-compose.yml
```

---

## Step 4: Add Local DNS Entries

This is the key configuration that makes local access to your services work without going through Cloudflare. This resolves `*.gmojsoski.com` domains to your ThinkCentre IP for local network access (fixes NAT hairpinning).

**Recommended Method: Use Pi-hole Admin UI**

1. Start Pi-hole first (see Step 5)
2. Go to `http://[REDACTED_INTERNAL_IP_2]/admin`
3. Navigate to: **Local DNS → DNS Records**
4. Add each subdomain individually:
   - Domain: `gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `www.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `cloud.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `files.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `jellyfin.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `vault.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `shopping.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `analytics.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `poker.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `bookmarks.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `tickets.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `paperless.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - Domain: `mattermost.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]`
   - (Add any other subdomains you have)

**Note:** Pi-hole Admin UI doesn't support wildcard syntax (`*.domain.com`), so each subdomain must be added individually. However, this ensures precise control and is the recommended approach.

---

## Step 5: Start Pi-hole

```bash
cd /path/to/repo/docker/pihole
docker compose up -d

# Wait for Pi-hole to fully start (about 30-60 seconds)
sleep 30

# Check if it's running and healthy
docker ps | grep pihole
docker logs pihole --tail 20

# Verify it's listening on ports 53 (DNS) and 80 (Web)
sudo ss -tulpn | grep -E ":(53|80)" | grep pihole
```

---

## Step 6: Test DNS Resolution

```bash
# Test that Pi-hole resolves local services correctly
dig @127.0.0.1 jellyfin.gmojsoski.com +short
# Expected output: [REDACTED_INTERNAL_IP_1]

dig @127.0.0.1 google.com +short
# Expected output: Google's IP addresses

# Test ad blocking
dig @127.0.0.1 ads.google.com +short
# Expected output: 0.0.0.0 (blocked)
```

---

## Step 7: Configure Router DHCP

### Option A: Router Admin Panel (Recommended)

1. Access your router admin panel (usually `http://192.168.1.1`)
2. Find **DHCP Settings** or **LAN Settings**
3. Set **Primary DNS Server** to: `[REDACTED_INTERNAL_IP_2]`
4. Optionally set **Secondary DNS Server** to: `1.1.1.1` (fallback)
5. Save and reboot router

### Option B: Manual Device Configuration

If you can't change router settings, manually set DNS on each device:
- DNS Server: `[REDACTED_INTERNAL_IP_2]`

---

## Step 8: Renew DHCP on Devices

After changing router DNS, devices need to get the new settings:

- **Reconnect to WiFi** (easiest)
- **Reboot device**
- **Renew DHCP lease manually:**
  - Windows: `ipconfig /release && ipconfig /renew`
  - macOS: System Preferences → Network → Advanced → TCP/IP → Renew DHCP Lease
  - Linux: `sudo dhclient -r && sudo dhclient`
  - iOS/Android: Toggle WiFi off and on

---

## Verification

### On any device (after DNS change)

```bash
# Check which DNS server is being used
nslookup jellyfin.gmojsoski.com

# Should show:
# Server: [REDACTED_INTERNAL_IP_2]
# Address: [REDACTED_INTERNAL_IP_1]
```

### In browser
- **HTTP (local, fast)**: Open `http://jellyfin.gmojsoski.com:8080` (port 8080 required)
- **HTTPS (via Cloudflare)**: Open `https://jellyfin.gmojsoski.com` (works both locally and externally)

**Note**: Port 8080 is required for local HTTP access because Caddy listens on port 8080 (not port 80) on the host. This applies to all services. For HTTPS, Cloudflare Tunnel handles routing automatically.

---

## Pi-hole Admin Interface

- **URL:** `http://[REDACTED_INTERNAL_IP_2]/admin`
- **Password:** Whatever you set in `WEBPASSWORD` (default: `changeme`)

### Useful Admin Pages
- **Dashboard:** Query statistics and blocking stats
- **Query Log:** See all DNS queries
- **Local DNS → DNS Records:** Add/edit local DNS entries via UI
- **Adlists:** Manage blocklists

---

## Common Commands

```bash
# Check Pi-hole status
docker ps | grep pihole

# View Pi-hole logs
docker logs pihole -f

# Restart Pi-hole
docker restart pihole

# Update Pi-hole
cd ~/pihole
docker compose pull
docker compose up -d

# Enter Pi-hole container
docker exec -it pihole bash

# Check Pi-hole version
docker exec pihole pihole -v
```

---

## Recommended Blocklists

Pi-hole comes with Steven Black hosts list by default. Recommended additional blocklists:

### OISD (Recommended - Low False Positives)
- **Small**: `https://small.oisd.nl`
- **Big**: `https://big.oisd.nl` (more comprehensive)

To add:
1. Go to Pi-hole Admin UI → **Group Management → Adlists**
2. Click **Add** and paste the URL
3. Click **Save**
4. Go to **Tools → Update Gravity** to download

**Note:** Requires Pi-hole FTL v5.22+ (v6.x is compatible)

## Adding New Services

When you add a new service to lemongrab, add a DNS entry via Pi-hole Admin UI:

1. Go to `http://[REDACTED_INTERNAL_IP_2]/admin`
2. Navigate to: **Local DNS → DNS Records**
3. Click **Add**
4. Enter: Domain: `newservice.gmojsoski.com` → IP: `[REDACTED_INTERNAL_IP_1]` (server IP)
5. Click **Add**
6. **Access the service**:
   - HTTP (local): `http://newservice.gmojsoski.com:8080` (port 8080 required)
   - HTTPS (via Cloudflare): `https://newservice.gmojsoski.com` (no port needed)

Pi-hole will automatically reload DNS - no restart needed.

---

## Troubleshooting

### Pi-hole container won't start
```bash
# Check if port 53 is in use
sudo lsof -i :53

# If systemd-resolved is using it:
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# Remove symlink and create static resolv.conf
sudo rm /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

### DNS not resolving
```bash
# Check Pi-hole is listening on port 53
sudo netstat -tulpn | grep :53

# Check Pi-hole logs for errors
docker logs pihole | tail -50

# Test DNS directly
dig @[REDACTED_INTERNAL_IP_2] google.com
```

### Local services still going through Cloudflare / Multiple IPs returned

**Problem**: `nslookup` shows both local IP (192.168.1.97) AND Cloudflare IPv6 addresses. This causes browsers to try IPv6 (Cloudflare) first instead of IPv4 (local).

**Root Cause**: Pi-hole forwards DNS queries upstream even when a Local DNS Record exists, causing both local IPv4 and upstream IPv6 to be returned.

**Solution (Recommended)**: Disable IPv6 in Pi-hole Admin UI:

1. **Access Pi-hole Admin**: `http://192.168.1.98/admin` (or your Pi-hole IP)
2. **Login** with your Pi-hole admin password
3. **Navigate to**: Settings → DNS (left sidebar)
4. **Scroll down** to "Advanced DNS settings"
5. **Uncheck**: "Enable IPv6 support" (or "Enable IPv6" depending on Pi-hole version)
6. **Click**: "Save" button
7. **Wait**: 30-60 seconds for Pi-hole to reload DNS settings
8. **On the Pi-hole device**, restart if needed: `docker restart pihole`

**Verify fix** (from any device on network):
```bash
nslookup mattermost.gmojsoski.com
```

**Expected output (fixed)** - should show ONLY IPv4:
```
Server:         192.168.1.98
Address:        192.168.1.98#53

Name:   mattermost.gmojsoski.com
Address: 192.168.1.97
```

**If you still see IPv6 addresses**:
- Clear DNS cache on your device: `sudo systemd-resolve --flush-caches` (Linux) or `ipconfig /flushdns` (Windows)
- Wait a few minutes for DNS cache to expire (TTL)
- Try again: `nslookup mattermost.gmojsoski.com`

**Alternative Solution 1**: Use custom dnsmasq configuration file (ON PI-HOLE DEVICE):

If disabling IPv6 in the admin UI doesn't work, create a custom dnsmasq config file:

1. **On your Raspberry Pi (Pi-hole device)**, SSH into it
2. **Create the config file**:
   ```bash
   sudo nano /etc/dnsmasq.d/99-block-ipv6-local-domains.conf
   ```
3. **Add this content**:
   ```conf
   # Block AAAA (IPv6) queries for local domains with Local DNS Records
   # This prevents forwarding IPv6 queries upstream for domains that have Local DNS Records
   
   # Block AAAA queries for specific domains (uncomment as needed):
   server=/mattermost.gmojsoski.com/#
   server=/jellyfin.gmojsoski.com/#
   server=/cloud.gmojsoski.com/#
   server=/files.gmojsoski.com/#
   server=/paperless.gmojsoski.com/#
   server=/bookmarks.gmojsoski.com/#
   server=/tickets.gmojsoski.com/#
   server=/poker.gmojsoski.com/#
   server=/analytics.gmojsoski.com/#
   ```
4. **Save** (Ctrl+O, Enter, Ctrl+X)
5. **Restart Pi-hole**:
   ```bash
   docker restart pihole
   # OR if not using Docker:
   sudo systemctl restart pihole-FTL
   ```

**Alternative Solution 2**: Use Pi-hole's Group Management to block AAAA (IPv6) queries:
1. Pi-hole Admin → Group Management → Domains
2. Add domain: `*.gmojsoski.com` with query type: `AAAA` (IPv6)
3. Add to "Blocked" group

**Why the Admin UI setting might not work**:
Pi-hole's "Disable IPv6" setting might not prevent it from forwarding AAAA queries upstream when a Local DNS Record exists. The Local DNS Record creates an A record (IPv4), but Pi-hole still forwards the AAAA query upstream. Using the custom dnsmasq config above explicitly prevents forwarding for those domains.

**Quick Workaround (Client-Side)**: If you can't modify Pi-hole right now, add entries to `/etc/hosts` on your devices:
```bash
# On lemongrab (main server) - add to /etc/hosts
192.168.1.97    mattermost.gmojsoski.com
192.168.1.97    jellyfin.gmojsoski.com
192.168.1.97    cloud.gmojsoski.com
# Add other services as needed
```

This bypasses DNS and forces local IP resolution. Note: This only works on the device where you edit `/etc/hosts`. For network-wide fix, use the Pi-hole solution above.

**Original troubleshooting steps**:
```bash
# Verify local DNS entries are loaded
docker exec pihole cat /etc/dnsmasq.d/02-local-dns.conf

# Check resolution
dig @[REDACTED_INTERNAL_IP_2] jellyfin.gmojsoski.com +short
# Should return [REDACTED_INTERNAL_IP_1], not Cloudflare IP

# If wrong, restart Pi-hole
docker restart pihole
```

### Devices not using Pi-hole
```bash
# Check device's DNS server
# Windows: ipconfig /all
# macOS/Linux: cat /etc/resolv.conf

# If still showing router or ISP DNS:
# 1. Verify router DHCP is set to [REDACTED_INTERNAL_IP_2]
# 2. Renew DHCP lease on device
# 3. Or manually set DNS to [REDACTED_INTERNAL_IP_2]
```

---

## Backup

### Backup Pi-hole configuration
```bash
cd ~/pihole
tar -czvf pihole-backup-$(date +%Y%m%d).tar.gz etc-pihole etc-dnsmasq.d
```

### Restore from backup
```bash
cd ~/pihole
tar -xzvf pihole-backup-YYYYMMDD.tar.gz
docker restart pihole
```

---

## Network Diagram

```
Internet
    │
    ▼
┌─────────────────┐
│  Cloudflare     │ (External access)
│  Tunnel         │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│                 Home Network                     │
│                                                  │
│  ┌──────────────┐      ┌──────────────────────┐ │
│  │ Raspberry Pi │      │ lemongrab            │ │
│  │ [REDACTED_INTERNAL_IP_2]│      │ [REDACTED_INTERNAL_IP_1]         │ │
│  │              │      │                      │ │
│  │ ┌──────────┐ │      │ ┌──────────────────┐ │ │
│  │ │ Pi-hole  │ │ DNS  │ │ Caddy (8080)     │ │ │
│  │ │ (DNS)    │◄──────►│ │ ├─ Jellyfin      │ │ │
│  │ └──────────┘ │      │ │ ├─ Nextcloud     │ │ │
│  └──────────────┘      │ │ ├─ Vaultwarden   │ │ │
│         ▲              │ │ ├─ KitchenOwl    │ │ │
│         │              │ │ └─ ...           │ │ │
│    DNS queries         │ └──────────────────┘ │ │
│         │              │                      │ │
│  ┌──────┴───────┐      │ ┌──────────────────┐ │ │
│  │ All Devices  │      │ │ Cloudflare       │ │ │
│  │ (Phone, PC,  │      │ │ Tunnel           │ │ │
│  │  TV, etc.)   │      │ └──────────────────┘ │ │
│  └──────────────┘      └──────────────────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## Quick Reference

| Item | Value |
|------|-------|
| Pi-hole IP | `[REDACTED_INTERNAL_IP_2]` |
| lemongrab IP | `[REDACTED_INTERNAL_IP_1]` |
| Pi-hole Admin | `http://[REDACTED_INTERNAL_IP_2]/admin` |
| DNS Port | `53` |
| Web Port | `80` |
| Config Location | `docker/pihole/` (in repository) |
| Local DNS | Configured via Admin UI (Local DNS → DNS Records) |
| Docker Volumes | `pihole_config`, `dnsmasq_config` (persistent) |
| Upstream DNS | `1.1.1.1`, `1.0.0.1` (Cloudflare) |

---

## Current Configuration (January 2026)

- **Hardware**: Raspberry Pi 4 Model B (4GB RAM)
- **Pi-hole Version**: v6.3+ (Core v6.3, Web v6.4, FTL v6.4.1)
- **Deployment**: Docker (network_mode: host)
- **Data Storage**: Docker volumes (persistent across container updates)
- **Local DNS**: Configured via Admin UI (12 subdomains pointing to ThinkCentre)
- **Blocklists**: 
  - Default: Steven Black hosts (75,488 domains)
  - Recommended: OISD Small (`https://small.oisd.nl`)
- **Status**: ✅ Operational - All devices using Pi-hole for DNS

---

*Last updated: January 2026*




