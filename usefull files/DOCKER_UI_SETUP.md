# Docker UI Setup Guide

Visual web-based interface for managing Docker containers.

## 🎯 Recommended: Portainer

**Portainer** is the most popular Docker UI - web-based, feature-rich, and easy to use.

### Features
- ✅ Web-based UI (access from browser)
- ✅ Container management (start, stop, restart, logs)
- ✅ Image management
- ✅ Volume and network management
- ✅ Docker Compose support
- ✅ Container stats and monitoring
- ✅ Terminal access to containers
- ✅ User management and access control

## 🚀 Quick Setup

### Option 1: Using Docker Compose (Recommended)

```bash
# Create directory
mkdir -p /mnt/ssd/docker-projects/portainer

# Copy docker-compose.yml
cp "/home/goce/Desktop/Cursor projects/Pi-version-control/docker/portainer/docker-compose.yml" /mnt/ssd/docker-projects/portainer/

# Start Portainer
cd /mnt/ssd/docker-projects/portainer
docker compose up -d

# Access at: http://localhost:9000 or https://localhost:9443
```

### Option 2: Direct Docker Run

```bash
docker run -d \
  -p 9000:9000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer-data:/data \
  portainer/portainer-ce:latest
```

## 🌐 Access Portainer

### Local Access
- **HTTP**: http://localhost:9000
- **HTTPS**: https://localhost:9443

### Via Cloudflare Tunnel (Recommended)

Add to your Cloudflare config (`~/.cloudflared/config.yml`):

```yaml
- hostname: portainer.gmojsoski.com
  service: http://localhost:9000
```

Then access via: https://portainer.gmojsoski.com

**Note**: You'll need to add the route to Caddyfile if you want it routed through Caddy first.

## 🔐 First Time Setup

1. Open Portainer in browser
2. Create admin account (username and password)
3. Select "Docker" environment
4. You're ready to use Portainer!

## 📊 What You Can Do

### Container Management
- View all containers (running and stopped)
- Start, stop, restart containers
- View container logs
- Access container terminal
- View container stats (CPU, memory, network)

### Image Management
- View all images
- Pull new images
- Remove unused images
- Build images from Dockerfile

### Volume & Network Management
- View volumes
- Create/remove volumes
- View networks
- Create/remove networks

### Docker Compose
- Deploy compose files
- View compose stacks
- Manage compose services

## 🎨 Alternative: Lazydocker (Terminal UI)

If you prefer a terminal-based UI:

```bash
# Download lazydocker
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

# Run it
lazydocker
```

**Features**:
- Terminal-based (works over SSH)
- Lightweight
- Quick container management
- View logs and stats

## 🔧 Integration with Your Setup

### Add Portainer to Caddy (Optional)

If you want to access via your domain through Caddy, add to Caddyfile:

```caddyfile
@portainer host portainer.gmojsoski.com
handle @portainer {
    encode gzip
    reverse_proxy http://localhost:9000 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
    }
}
```

### Add to Health Check

Portainer will auto-restart (restart: always), but you can add to health check if needed:

```bash
# Already handled by restart: always policy
```

## 📝 Quick Commands

```bash
# Start Portainer
cd /mnt/ssd/docker-projects/portainer
docker compose up -d

# View logs
docker logs portainer

# Stop Portainer
docker compose down

# Update Portainer
docker compose pull
docker compose up -d
```

## 🆚 Portainer vs Lazydocker

| Feature | Portainer | Lazydocker |
|---------|-----------|------------|
| **Type** | Web UI | Terminal UI |
| **Access** | Browser | SSH/Terminal |
| **Features** | Full-featured | Basic management |
| **Resource Usage** | Higher | Lower |
| **Best For** | Full management | Quick tasks |

## 🎯 Recommendation

**Use Portainer** for:
- Full Docker management
- Web-based access
- Team collaboration
- Comprehensive monitoring

**Use Lazydocker** for:
- Quick terminal access
- Lightweight management
- SSH-only environments

## 🔒 Security Notes

- Portainer has access to all Docker containers
- Use strong password for admin account
- Consider access control if exposing publicly
- Cloudflare Tunnel provides security layer

## 📚 Resources

- Portainer Docs: https://docs.portainer.io/
- Portainer GitHub: https://github.com/portainer/portainer
- Lazydocker: https://github.com/jesseduffield/lazydocker

