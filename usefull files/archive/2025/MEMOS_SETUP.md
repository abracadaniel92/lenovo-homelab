# Memos Setup Guide

Memos is a simple, self-hosted note-taking application perfect for shared notes with multi-language support.

## 🚀 Quick Start

### 1. Run Setup Script

```bash
cd "/home/goce/Desktop/Cursor projects/Lenovo scripts"
./setup-memos.sh
```

This will:
- Create the directory structure at `/mnt/ssd/docker-projects/memos`
- Copy the Docker Compose configuration
- Start the Memos container

### 2. Access Memos

- **Web Interface**: https://notes.gmojsoski.com
- **Local**: http://localhost:8093

### 3. Create Your Account

1. Open the web interface
2. Click "Sign Up" to create your first account
3. This account will be the admin account

### 4. Add Users

1. Log in as admin
2. Go to Settings → Users
3. Click "Invite User" or share the signup link
4. Users can create accounts and share notes

## 📁 Directory Structure

```
/mnt/ssd/docker-projects/memos/
├── docker-compose.yml
└── data/
    └── (database and files stored here)
```

## 🔧 Configuration

### Docker Compose

Location: `/mnt/ssd/docker-projects/memos/docker-compose.yml`

Key settings:
- **Port**: `8093:5230` (Host:Container)
- **Data**: Stored in `./data` directory
- **Timezone**: Europe/Skopje

### Caddy Configuration

The Caddyfile routes `notes.gmojsoski.com` → `http://172.17.0.1:8093`

### Cloudflare Tunnel

The tunnel configuration includes:
```yaml
- hostname: notes.gmojsoski.com
  service: http://localhost:8080
```

## 📱 Features

- **Simple Interface**: Clean, minimal design
- **Markdown Support**: Write notes in Markdown
- **Multi-language**: Change language in Settings
- **Multi-user**: Share notes with others
- **Tags**: Organize notes with tags
- **Search**: Full-text search
- **Mobile-friendly**: Works great on mobile browsers
- **Privacy**: All data stored on your server

## 👥 User Management

### Adding Users

1. Log in as admin
2. Go to Settings → Users
3. Click "Invite User"
4. Enter email address (or share signup link)
5. User creates account and can access shared notes

### Sharing Notes

- Notes can be shared with specific users
- Or made public with a shareable link
- Real-time collaboration on shared notes

## 🌍 Multi-language Support

1. Go to Settings
2. Select your preferred language
3. Interface and content support multiple languages
4. You can write notes in any language

## 🔐 Security

- **HTTPS**: Enforced via Cloudflare Tunnel
- **Authentication**: Required for all access
- **Data**: Stored locally on your server
- **Privacy**: No data sent to external services

## 📊 Backup

### Manual Backup

```bash
# Backup the data directory
tar -czf memos-backup-$(date +%Y%m%d).tar.gz /mnt/ssd/docker-projects/memos/data/
```

### Restore

```bash
# Stop Memos
cd /mnt/ssd/docker-projects/memos
docker compose down

# Restore data
tar -xzf memos-backup-YYYYMMDD.tar.gz -C /

# Start Memos
docker compose up -d
```

## 🛠️ Management Commands

```bash
cd /mnt/ssd/docker-projects/memos

# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f

# Restart
docker compose restart

# Update
docker compose pull
docker compose up -d
```

## 🐛 Troubleshooting

### Container won't start

```bash
# Check logs
docker logs memos

# Check if port is in use
sudo netstat -tulpn | grep 8093
```

### Can't access web interface

1. Check container is running: `docker ps | grep memos`
2. Check port mapping: `docker port memos`
3. Test locally: `curl http://localhost:8093`
4. Check Caddy logs: `docker logs caddy`

### Notes not syncing

- Check if users are properly added
- Verify sharing settings on notes
- Check container logs for errors

## 📚 Additional Resources

- **GitHub**: https://github.com/usememos/memos
- **Documentation**: https://www.usememos.com/docs
- **Docker Hub**: https://hub.docker.com/r/neosmemo/memos

## 🔄 Updates

Memos updates automatically when you pull the latest image:

```bash
cd /mnt/ssd/docker-projects/memos
docker compose pull
docker compose up -d
```

Or use Watchtower for automatic updates (if configured).


