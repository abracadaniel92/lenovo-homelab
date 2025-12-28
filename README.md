# Lenovo ThinkCentre Configuration & Setup

This repository contains all configuration files and setup instructions for replicating this self-hosted server setup. The server runs multiple services including Docker containers, reverse proxy (Caddy), Cloudflare Tunnel, and various applications.

## 📋 Table of Contents

- [Overview](#overview)
- [System Requirements](#system-requirements)
- [Installed Services](#installed-services)
- [Directory Structure](#directory-structure)
- [Setup Instructions](#setup-instructions)
- [Service Details](#service-details)
- [Maintenance](#maintenance)

## 🎯 Overview

This Lenovo ThinkCentre serves as a self-hosted server running:
- **Reverse Proxy**: Caddy (handles HTTPS termination and routing)
- **Tunnel**: Cloudflare Tunnel (exposes services securely to the internet)
- **File Sharing**: Gokapi
- **Analytics**: GoatCounter
- **Cloud Storage**: Nextcloud
- **Monitoring**: Uptime Kuma
- **DNS/Ad Blocking**: Pi-hole
- **Document Processing**: Documents-to-Calendar app
- **Bookmarks**: Slack bookmarks Flask service
- **Planning Poker**: Planning poker web application
- **Docker Management**: Portainer (web UI)
- **Service Dashboard**: Homepage
- **Auto-Updates**: Watchtower
- **File Manager**: FileBrowser

## 💻 System Requirements

- Lenovo ThinkCentre or similar x86_64 system
- Docker and Docker Compose installed
- SSD mounted at `/mnt/ssd` (recommended for better performance)
- Cloudflare account with tunnel configured
- Domain name with DNS configured

## 📦 Installed Services

### Docker Containers

1. **Caddy** - Reverse proxy and web server
   - Port: 8080 (HTTP), 8443 (HTTPS)
   - Location: `/mnt/ssd/docker-projects/caddy`

2. **GoatCounter** - Privacy-friendly web analytics
   - Port: 8088
   - Location: `/mnt/ssd/docker-projects/goatcounter`

3. **Nextcloud** - Self-hosted cloud storage
   - Port: 8081
   - Location: `/mnt/ssd/apps/nextcloud`

4. **Uptime Kuma** - Uptime monitoring
   - Port: 3001
   - Location: `/mnt/ssd/docker-projects/uptime-kuma`

5. **Documents-to-Calendar** - Document processing app
   - Port: 8000
   - Location: `/mnt/ssd/docker-projects/documents-to-calendar`

6. **Pi-hole** - DNS sinkhole and ad blocker
   - Network: Host mode
   - Location: Docker volume

7. **Portainer** - Docker management UI
   - Port: 9000 (HTTP), 9443 (HTTPS)
   - Location: `/mnt/ssd/docker-projects/portainer`

8. **Homepage** - Service dashboard
   - Port: 3002
   - Location: `/mnt/ssd/docker-projects/homepage`

9. **Watchtower** - Auto-update Docker containers
   - No web UI (runs in background)
   - Location: `/mnt/ssd/docker-projects/watchtower`

10. **FileBrowser** - Web file manager
    - Port: 8082
    - Location: `/mnt/ssd/docker-projects/filebrowser`

### System Services

1. **Gokapi** - File sharing service
   - Port: 8091
   - Location: `/mnt/ssd/apps/gokapi`
   - Service: `/etc/systemd/system/gokapi.service`

2. **Cloudflare Tunnel** - Secure tunnel to Cloudflare
   - Config: `/home/goce/.cloudflared/config.yml`
   - Service: `/etc/systemd/system/cloudflared.service`

3. **Bookmarks** - Slack bookmarks Flask service
   - Port: 5000
   - Location: `/mnt/ssd/apps/bookmarks`
   - Service: `/etc/systemd/system/bookmarks.service`

4. **Planning Poker** - Planning poker web application
   - Port: 3000
   - Location: `/home/goce/Desktop/Cursor projects/planning poker/planning_poker`
   - Service: `/etc/systemd/system/planning-poker.service`

## 📁 Directory Structure

```
Lenovo-version-control/
├── docker/
│   ├── caddy/
│   │   ├── docker-compose.yml
│   │   └── Caddyfile
│   ├── goatcounter/
│   │   └── docker-compose.yml
│   ├── nextcloud/
│   │   └── docker-compose.yml
│   ├── uptime-kuma/
│   │   └── docker-compose.yml
│   ├── documents-to-calendar/
│   │   ├── docker-compose.yml
│   │   └── Dockerfile
│   └── pihole/
│       └── docker-compose.yml
├── systemd/
│   ├── gokapi.service
│   ├── cloudflared.service
│   ├── bookmarks.service
│   └── planning-poker.service
├── cloudflare/
│   └── config.yml
├── gokapi/
│   └── config.json
└── README.md
```

## 🚀 Setup Instructions

### 1. Initial System Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose plugin
sudo apt-get install docker-compose-plugin -y

# Log out and back in for group changes to take effect
```

### 2. Mount SSD (if applicable)

```bash
# Find your SSD
lsblk

# Mount to /mnt/ssd (adjust device name)
sudo mkdir -p /mnt/ssd
sudo mount /dev/sda1 /mnt/ssd  # Adjust device name

# Add to /etc/fstab for permanent mounting
sudo nano /etc/fstab
# Add: /dev/sda1 /mnt/ssd ext4 defaults 0 2
```

### 3. Create Directory Structure

```bash
# Create directories for Docker projects
sudo mkdir -p /mnt/ssd/docker-projects/{caddy,goatcounter,uptime-kuma,documents-to-calendar}
sudo mkdir -p /mnt/ssd/apps/{nextcloud,gokapi,gokapi-data,gokapi-config}

# Set ownership
sudo chown -R $USER:$USER /mnt/ssd/docker-projects
sudo chown -R $USER:$USER /mnt/ssd/apps
```

### 4. Setup Caddy

```bash
cd /mnt/ssd/docker-projects/caddy
mkdir -p config data site

# Copy Caddyfile
cp /path/to/repo/docker/caddy/Caddyfile ./config/

# Copy docker-compose.yml
cp /path/to/repo/docker/caddy/docker-compose.yml ./

# Start Caddy
docker compose up -d
```

### 5. Setup Cloudflare Tunnel

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb

# Create config directory
mkdir -p ~/.cloudflared

# Copy config (update credentials file path)
cp /path/to/repo/cloudflare/config.yml ~/.cloudflared/

# Place your tunnel credentials file at:
# ~/.cloudflared/df638884-0d3e-4799-8a98-60e844fcd164.json

# Install systemd service
sudo cp /path/to/repo/systemd/cloudflared.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cloudflared.service
sudo systemctl start cloudflared.service
```

### 6. Setup Gokapi

```bash
# Download Gokapi binary (x86_64)
cd /mnt/ssd/apps/gokapi
wget https://github.com/Forceu/Gokapi/releases/latest/download/gokapi-linux-amd64
mv gokapi-linux-amd64 gokapi
chmod +x gokapi

# Create config directory
mkdir -p config

# Copy config template and customize
cp /path/to/repo/gokapi/config.json.template ./config/config.json
# Edit config.json and update:
# - SaltAdmin: Generate a random string
# - SaltFiles: Generate a random string  
# - Username: Your email
# - ServerUrl: Your domain
# - Cipher: Generate via Gokapi or leave empty for auto-generation

# Create data directory
mkdir -p /mnt/ssd/apps/gokapi-data

# Install systemd service
sudo cp /path/to/repo/systemd/gokapi.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gokapi.service
sudo systemctl start gokapi.service
```

### 7. Setup Docker Services

#### GoatCounter

```bash
cd /mnt/ssd/docker-projects/goatcounter
cp /path/to/repo/docker/goatcounter/docker-compose.yml ./
mkdir -p goatcounter-data
docker compose up -d
```

#### Nextcloud

```bash
cd /mnt/ssd/apps/nextcloud
cp /path/to/repo/docker/nextcloud/docker-compose.yml ./

# Update POSTGRES_PASSWORD in docker-compose.yml
nano docker-compose.yml

# Create directories
mkdir -p db app

# Start services
docker compose up -d
```

#### Uptime Kuma

```bash
cd /mnt/ssd/docker-projects/uptime-kuma
cp /path/to/repo/docker/uptime-kuma/docker-compose.yml ./
mkdir -p data
docker compose up -d
```

#### Documents-to-Calendar

```bash
cd /mnt/ssd/docker-projects/documents-to-calendar
cp /path/to/repo/docker/documents-to-calendar/docker-compose.yml ./
cp /path/to/repo/docker/documents-to-calendar/Dockerfile ./

# Create necessary directories
mkdir -p uploads temp data

# Create .env file with required variables
nano .env
# Add: GOOGLE_API_KEY, ADMIN_PASSWORD, JWT_SECRET_KEY, CREDENTIALS_JSON, etc.

# Build and start
docker compose build
docker compose up -d
```

#### Pi-hole

```bash
cd /mnt/ssd/docker-projects/pihole
cp /path/to/repo/docker/pihole/docker-compose.yml ./

# Update timezone and web password in docker-compose.yml
nano docker-compose.yml

# Start
docker compose up -d
```

## 🔧 Service Details

### Port Mapping

- **8080**: Caddy (HTTP)
- **8443**: Caddy (HTTPS)
- **8088**: GoatCounter
- **8091**: Gokapi
- **8081**: Nextcloud
- **3001**: Uptime Kuma
- **8000**: Documents-to-Calendar
- **5000**: Bookmarks
- **3000**: Planning Poker
- **3002**: Homepage
- **8082**: FileBrowser
- **9000**: Portainer (HTTP)
- **9443**: Portainer (HTTPS)
- **53**: Pi-hole (DNS)

### Domain Routing (via Caddy)

- `gmojsoski.com` / `www.gmojsoski.com` → Static site (port 8080)
- `analytics.gmojsoski.com` → GoatCounter (port 8088)
- `files.gmojsoski.com` → Gokapi (port 8091)
- `cloud.gmojsoski.com` → Nextcloud (port 8081) - **Note**: Uses host IP (172.17.0.1:8081) due to different Docker networks
- `bookmarks.gmojsoski.com` → Bookmarks server (port 5000)
- `poker.gmojsoski.com` → Planning Poker (port 3000)
- `tickets.gmojsoski.com` → Documents-to-Calendar (port 8000)
- `travelsync.gmojsoski.com` → Travelsync/Documents-to-Calendar (port 8000)

### Cloudflare Tunnel Configuration

The Cloudflare tunnel routes all domains through Cloudflare's network, providing:
- DDoS protection
- SSL/TLS termination
- Global CDN
- WAF (Web Application Firewall)

All services are routed to `localhost:8080` where Caddy handles the internal routing.

## 🔐 Security Notes

1. **Passwords**: Update all default passwords in docker-compose.yml files
   - Nextcloud: `POSTGRES_PASSWORD`
   - Pi-hole: `WEBPASSWORD`
   - Documents-to-Calendar: `ADMIN_PASSWORD`, `JWT_SECRET_KEY`

2. **Credentials**: 
   - Cloudflare tunnel credentials file should be kept secure
   - Google API credentials for Documents-to-Calendar should be in `.env` file
   - Gokapi config contains authentication salts - use `config.json.template` and generate your own salts
   - **Important**: The actual `gokapi/config.json` with real salts is excluded from git. Use the template and generate new salts when setting up.

3. **Firewall**: Consider setting up UFW or similar:
   ```bash
   sudo apt install ufw
   sudo ufw allow 22/tcp  # SSH
   sudo ufw allow 53/udp  # Pi-hole DNS
   sudo ufw enable
   ```

## 📝 Environment Variables

### Documents-to-Calendar (.env file)

```env
GOOGLE_API_KEY=your-api-key
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-password
JWT_SECRET_KEY=your-64-char-secret
CREDENTIALS_JSON=base64-encoded-credentials
GOOGLE_CALENDAR_HEADLESS=true
```

## 🔄 Maintenance

### Update Services

```bash
# Update Docker images
docker compose pull
docker compose up -d

# Restart specific service
docker compose restart <service-name>

# View logs
docker compose logs -f <service-name>
```

### Backup Important Data

```bash
# Backup directories
- /mnt/ssd/apps/nextcloud/app
- /mnt/ssd/apps/nextcloud/db
- /mnt/ssd/apps/gokapi-data
- /mnt/ssd/docker-projects/goatcounter/goatcounter-data
- /mnt/ssd/docker-projects/uptime-kuma/data
- /mnt/ssd/docker-projects/documents-to-calendar/data
```

### Check Service Status

```bash
# Docker services
docker ps

# System services
systemctl status gokapi
systemctl status cloudflared
```

## 🐛 Troubleshooting

### Service won't start

1. Check logs: `docker compose logs <service>` or `journalctl -u <service>`
2. Verify ports aren't in use: `sudo netstat -tulpn | grep <port>`
3. Check file permissions
4. Verify environment variables are set

### Cloudflare Tunnel issues

1. Verify credentials file exists and is readable
2. Check tunnel status: `cloudflared tunnel list`
3. View logs: `journalctl -u cloudflared -f`

### Caddy routing issues

1. Check Caddyfile syntax: `docker exec caddy caddy validate --config /etc/caddy/Caddyfile`
2. Reload Caddy: `docker exec caddy caddy reload --config /etc/caddy/Caddyfile`
3. Check container networking: `docker network inspect bridge`

## 📚 Additional Resources

- [Caddy Documentation](https://caddyserver.com/docs/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Gokapi GitHub](https://github.com/Forceu/Gokapi)
- [GoatCounter Docs](https://www.goatcounter.com/)
- [Nextcloud Documentation](https://docs.nextcloud.com/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)

## 📄 License

This repository contains configuration files for personal use. Please review and update all credentials and secrets before deploying.

---

**Last Updated**: December 2025
**System**: Lenovo ThinkCentre with x86_64 architecture
**OS**: Linux (Debian)

