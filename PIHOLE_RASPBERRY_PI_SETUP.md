# Pi-hole Setup on Raspberry Pi 4

## Network Configuration
- **Raspberry Pi 4 IP:** `192.168.1.137`
- **lemongrab (main server) IP:** `192.168.1.97`

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

```bash
cat > docker-compose.yml << 'EOF'
services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    hostname: pihole
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
    environment:
      TZ: 'Europe/Skopje'
      WEBPASSWORD: 'changeme'  # CHANGE THIS PASSWORD!
      FTLCONF_LOCAL_IPV4: '192.168.1.137'
      PIHOLE_DNS_: '1.1.1.1;1.0.0.1'  # Upstream DNS (Cloudflare)
    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
EOF
```

---

## Step 4: Create Local DNS Entries

This is the key configuration that makes local access to your services work without going through Cloudflare.

```bash
mkdir -p etc-dnsmasq.d

cat > etc-dnsmasq.d/02-local-dns.conf << 'EOF'
# Local DNS entries for gmojsoski.com services
# Points to lemongrab (192.168.1.97) for local network access
# This fixes NAT hairpinning issues

# Main domain
address=/gmojsoski.com/192.168.1.97
address=/www.gmojsoski.com/192.168.1.97

# Services
address=/jellyfin.gmojsoski.com/192.168.1.97
address=/cloud.gmojsoski.com/192.168.1.97
address=/vault.gmojsoski.com/192.168.1.97
address=/shopping.gmojsoski.com/192.168.1.97
address=/files.gmojsoski.com/192.168.1.97
address=/analytics.gmojsoski.com/192.168.1.97
address=/poker.gmojsoski.com/192.168.1.97
address=/bookmarks.gmojsoski.com/192.168.1.97
address=/tickets.gmojsoski.com/192.168.1.97
address=/travelsync.gmojsoski.com/192.168.1.97
EOF
```

---

## Step 5: Start Pi-hole

```bash
cd ~/pihole
docker compose up -d

# Wait for Pi-hole to fully start (about 30-60 seconds)
sleep 30

# Check if it's running
docker ps
docker logs pihole
```

---

## Step 6: Test DNS Resolution

```bash
# Test that Pi-hole resolves local services correctly
dig @127.0.0.1 jellyfin.gmojsoski.com +short
# Expected output: 192.168.1.97

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
3. Set **Primary DNS Server** to: `192.168.1.137`
4. Optionally set **Secondary DNS Server** to: `1.1.1.1` (fallback)
5. Save and reboot router

### Option B: Manual Device Configuration

If you can't change router settings, manually set DNS on each device:
- DNS Server: `192.168.1.137`

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
# Server: 192.168.1.137
# Address: 192.168.1.97
```

### In browser
- Open `http://jellyfin.gmojsoski.com`
- Should load locally (fast) instead of going through Cloudflare

---

## Pi-hole Admin Interface

- **URL:** `http://192.168.1.137/admin`
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

## Adding New Services

When you add a new service to lemongrab, add a DNS entry:

### Option 1: Edit config file and restart
```bash
# Add to ~/pihole/etc-dnsmasq.d/02-local-dns.conf
echo "address=/newservice.gmojsoski.com/192.168.1.97" >> ~/pihole/etc-dnsmasq.d/02-local-dns.conf

# Restart Pi-hole
docker restart pihole
```

### Option 2: Use Pi-hole Admin UI
1. Go to `http://192.168.1.137/admin`
2. Local DNS → DNS Records
3. Add domain and IP
4. Click Add

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
dig @192.168.1.137 google.com
```

### Local services still going through Cloudflare
```bash
# Verify local DNS entries are loaded
docker exec pihole cat /etc/dnsmasq.d/02-local-dns.conf

# Check resolution
dig @192.168.1.137 jellyfin.gmojsoski.com +short
# Should return 192.168.1.97, not Cloudflare IP

# If wrong, restart Pi-hole
docker restart pihole
```

### Devices not using Pi-hole
```bash
# Check device's DNS server
# Windows: ipconfig /all
# macOS/Linux: cat /etc/resolv.conf

# If still showing router or ISP DNS:
# 1. Verify router DHCP is set to 192.168.1.137
# 2. Renew DHCP lease on device
# 3. Or manually set DNS to 192.168.1.137
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
│  │ 192.168.1.137│      │ 192.168.1.97         │ │
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
| Pi-hole IP | `192.168.1.137` |
| lemongrab IP | `192.168.1.97` |
| Pi-hole Admin | `http://192.168.1.137/admin` |
| DNS Port | `53` |
| Web Port | `80` |
| Config Location | `~/pihole/` |
| Local DNS File | `~/pihole/etc-dnsmasq.d/02-local-dns.conf` |
| Upstream DNS | `1.1.1.1`, `1.0.0.1` (Cloudflare) |

---

*Last updated: January 2026*

