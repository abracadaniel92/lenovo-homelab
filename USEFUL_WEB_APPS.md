# Useful Web-Based Apps for Your Server

Web-based applications that complement your existing setup.

## 🎯 High Priority Recommendations

### 1. **Homepage** - Service Dashboard ⭐
**What**: Beautiful dashboard that shows all your services in one place  
**Why**: Single page to see status of all services, quick links, system stats  
**Install**: Docker container  
**Port**: 3000 (or your choice)

```yaml
# docker-compose.yml
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: always
    ports:
      - "3002:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
```

**Features**:
- Service status monitoring
- Quick links to all services
- System stats (CPU, RAM, disk)
- Weather, date/time widgets
- Customizable layout

### 2. **Watchtower** - Auto-Update Containers ⭐
**What**: Automatically updates Docker containers to latest versions  
**Why**: Keeps all containers up-to-date without manual intervention  
**Install**: Docker container (runs in background)

```yaml
# docker-compose.yml
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *  # 2 AM daily
```

**Features**:
- Auto-updates containers
- Removes old images
- Configurable schedule
- No web UI (runs in background)

### 3. **FileBrowser** - Web File Manager
**What**: Web-based file manager (like Dropbox web interface)  
**Why**: Manage files via browser, upload/download, edit files  
**Install**: Docker container  
**Port**: 8082

```yaml
# docker-compose.yml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    restart: always
    ports:
      - "8082:80"
    volumes:
      - /mnt/ssd:/srv
      - ./filebrowser-data:/data
```

**Features**:
- Browse files via web
- Upload/download files
- Edit text files
- Share files
- User management

## 🟡 Medium Priority (Nice to Have)

### 4. **Netdata** - Real-Time System Monitoring
**What**: Real-time system and application monitoring  
**Why**: Detailed metrics, alerts, beautiful dashboards  
**Install**: Docker container  
**Port**: 19999

```yaml
# docker-compose.yml
services:
  netdata:
    image: netdata/netdata:latest
    container_name: netdata
    restart: always
    ports:
      - "19999:19999"
    volumes:
      - netdata-config:/etc/netdata
      - netdata-lib:/var/lib/netdata
      - netdata-cache:/var/cache/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined

volumes:
  netdata-config:
  netdata-lib:
  netdata-cache:
```

**Features**:
- Real-time metrics
- System, Docker, network monitoring
- Alerts and notifications
- Beautiful dashboards

### 5. **Vaultwarden** - Password Manager
**What**: Self-hosted Bitwarden-compatible password manager  
**Why**: Secure password storage, sync across devices  
**Install**: Docker container  
**Port**: 8083

```yaml
# docker-compose.yml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: always
    ports:
      - "8083:80"
    volumes:
      - ./vaultwarden-data:/data
    environment:
      - ADMIN_TOKEN=your-secure-token-here
```

**Features**:
- Password storage
- Browser extensions
- Mobile apps
- Secure sync

### 6. **Heimdall** - Application Dashboard
**What**: Simple dashboard for all your services  
**Why**: Alternative to Homepage, simpler setup  
**Install**: Docker container  
**Port**: 3003

```yaml
# docker-compose.yml
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    container_name: heimdall
    restart: always
    ports:
      - "3003:80"
    volumes:
      - ./heimdall-data:/config
```

**Features**:
- Service links
- Customizable icons
- Simple interface

## 🔵 Optional (Specialized Use Cases)

### 7. **Grafana** - Advanced Monitoring
**What**: Advanced monitoring and visualization  
**Why**: If you need detailed metrics and custom dashboards  
**Install**: Docker container (requires Prometheus for data)  
**Port**: 3004

**Note**: More complex setup, requires Prometheus for metrics

### 8. **Jellyfin** - Media Server
**What**: Self-hosted media server (like Plex)  
**Why**: Stream movies, TV shows, music  
**Install**: Docker container  
**Port**: 8096

**Note**: Only if you want media streaming

### 9. **Nginx Proxy Manager** - Alternative to Caddy
**What**: Web UI for managing reverse proxy  
**Why**: Alternative to Caddy with web UI  
**Install**: Docker container  
**Port**: 81 (admin), 80/443 (proxy)

**Note**: You already have Caddy, so not needed unless you want a UI

## 📊 Comparison Table

| App | Purpose | Priority | Complexity |
|-----|---------|----------|------------|
| **Homepage** | Service dashboard | ⭐⭐⭐ High | Easy |
| **Watchtower** | Auto-updates | ⭐⭐⭐ High | Easy |
| **FileBrowser** | File manager | ⭐⭐ Medium | Easy |
| **Netdata** | System monitoring | ⭐⭐ Medium | Medium |
| **Vaultwarden** | Password manager | ⭐⭐ Medium | Easy |
| **Heimdall** | Service dashboard | ⭐ Low | Easy |

## 🚀 Quick Install Scripts

### Install Homepage
```bash
mkdir -p /mnt/ssd/docker-projects/homepage/config
cd /mnt/ssd/docker-projects/homepage

cat > docker-compose.yml <<EOF
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: always
    ports:
      - "3002:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
EOF

docker compose up -d
```

### Install Watchtower
```bash
mkdir -p /mnt/ssd/docker-projects/watchtower
cd /mnt/ssd/docker-projects/watchtower

cat > docker-compose.yml <<EOF
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 2 * * *
EOF

docker compose up -d
```

### Install FileBrowser
```bash
mkdir -p /mnt/ssd/docker-projects/filebrowser
cd /mnt/ssd/docker-projects/filebrowser

cat > docker-compose.yml <<EOF
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: filebrowser
    restart: always
    ports:
      - "8082:80"
    volumes:
      - /mnt/ssd:/srv
      - ./filebrowser-data:/data
EOF

docker compose up -d
```

## 🎯 My Recommendations

### Start With These 3:

1. **Homepage** - Beautiful dashboard for all services
2. **Watchtower** - Auto-update containers (set and forget)
3. **FileBrowser** - Web file manager (very useful)

### Then Consider:

4. **Netdata** - If you want detailed system monitoring
5. **Vaultwarden** - If you want self-hosted password manager

## 📝 Integration with Your Setup

### Add to Caddyfile
```caddyfile
@homepage host homepage.gmojsoski.com
handle @homepage {
    encode gzip
    reverse_proxy http://172.17.0.1:3002 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
    }
}

@filebrowser host files.gmojsoski.com
handle @filebrowser {
    encode gzip
    reverse_proxy http://172.17.0.1:8082 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
    }
}
```

### Add to Cloudflare Config
```yaml
- hostname: homepage.gmojsoski.com
  service: http://localhost:8080

- hostname: filebrowser.gmojsoski.com
  service: http://localhost:8080
```

## 🔍 What You Already Have

- ✅ **Portainer** - Docker management
- ✅ **Uptime Kuma** - Service monitoring
- ✅ **Caddy** - Reverse proxy
- ✅ **Nextcloud** - Cloud storage
- ✅ **GoatCounter** - Analytics

## 💡 Pro Tips

1. **Homepage** is great for a single dashboard showing all services
2. **Watchtower** runs in background - set it up and forget it
3. **FileBrowser** is very useful for managing files via web
4. Start with 1-2 apps, don't install everything at once
5. All apps can be accessed via Portainer once installed

## 📚 Resources

- Homepage: https://gethomepage.dev/
- Watchtower: https://containrrr.dev/watchtower/
- FileBrowser: https://filebrowser.org/
- Netdata: https://www.netdata.cloud/
- Vaultwarden: https://github.com/dani-garcia/vaultwarden

