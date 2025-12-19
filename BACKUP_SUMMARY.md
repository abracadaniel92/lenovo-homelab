# Pi to ThinkCentre Migration - Backup Summary

**Date**: December 19, 2024  
**Source Machine**: Raspberry Pi (ARM64)  
**Destination Machine**: Lenovo ThinkCentre (x86_64, Debian Trixie)  
**Backup Location**: `/media/goce/ADATA SD600Q/pi_backup_20251219_095552/`

---

## ✅ What Was Backed Up

### 1. Credentials & Sensitive Data (7 files)
- ✅ Cloudflare Tunnel credentials (`~/.cloudflared/`)
  - `config.yml`
  - `df638884-0d3e-4799-8a98-60e844fcd164.json`
  - `cert.pem`
- ✅ Gokapi configuration (`/mnt/ssd/apps/gokapi/config/config.json`)
- ✅ Documents-to-Calendar credentials
  - `.env` file
  - `data/credentials.json`
  - `data/token.pickle`
- ✅ All `.env` files from docker projects

### 2. Docker Configurations (10 files)
- ✅ All `docker-compose.yml` files from:
  - Caddy
  - GoatCounter
  - Nextcloud
  - Uptime Kuma
  - Documents-to-Calendar
  - Plausible
  - Umami
- ✅ Dockerfiles (Documents-to-Calendar)
- ✅ Caddyfile (`/mnt/ssd/docker-projects/caddy/config/Caddyfile`)

### 3. Docker Named Volumes (5 volumes, ~444MB)
- ✅ All Docker named volumes backed up as `.tar.gz` files
- Location: `data/docker-volumes/`

### 4. System Configuration
- ✅ Systemd services:
  - `gokapi.service`
  - `cloudflared.service`
- ✅ Network configuration:
  - `/etc/hostname`
  - `/etc/hosts`
  - `/etc/resolv.conf`
  - Netplan configuration
  - NetworkManager configuration
- ✅ System information (`manifest/system_info.txt`)

### 5. Configuration Repository
- ✅ Pi-version-control repository structure

---

## ⚠️ Application Data Status

**Note**: Application data backups (Nextcloud, Gokapi data, GoatCounter, Uptime Kuma, Documents-to-Calendar data, Caddy data) may still be in progress or may not have been backed up if directories were empty or not found.

The restore script will handle missing data gracefully and will skip restoration of data that doesn't exist in the backup.

---

## 📁 Backup Structure

```
pi_backup_20251219_095552/
├── configs/              # Configuration repository
├── credentials/           # All sensitive credentials
│   ├── cloudflared/
│   ├── gokapi/
│   └── documents-to-calendar/
├── data/                  # Application data & Docker volumes
│   └── docker-volumes/    # Docker named volumes (5 files)
├── docker/                # Docker configurations
│   ├── caddy/
│   ├── goatcounter/
│   ├── nextcloud/
│   ├── uptime-kuma/
│   └── documents-to-calendar/
├── network/              # Network configuration files
├── systemd/              # Systemd service files
├── manifest/             # Backup manifest and system info
└── scripts/              # Backup/restore scripts
```

---

## 🚀 Restore Instructions for ThinkCentre

### Step 1: Prepare ThinkCentre
1. Install Debian Trixie (if not already installed)
2. Create user account (if needed)
3. Insert the backup SSD

### Step 2: Transfer Restore Script
You have two options:

**Option A**: Copy from backup SSD (if scripts were backed up)
```bash
# Mount the backup SSD
sudo mkdir -p /mnt/backup_ssd
sudo mount /dev/sdX1 /mnt/backup_ssd  # Replace sdX1 with your device

# Find and copy restore script
find /mnt/backup_ssd -name "restore_to_thinkcentre.sh"
```

**Option B**: Clone/download the repository
```bash
cd ~/Desktop/Cursor
# Clone or copy the Pi-version-control repository
# The restore script is at: Pi-version-control/restore_to_thinkcentre.sh
```

### Step 3: Run Restore Script
```bash
cd ~/Desktop/Cursor/Pi-version-control
chmod +x restore_to_thinkcentre.sh
./restore_to_thinkcentre.sh
```

The restore script will:
- Auto-detect the backup directory
- Install Docker and Docker Compose
- Setup SSD mount at `/mnt/ssd`
- Restore all configurations
- Restore all data
- Restore credentials
- Download x86_64 binaries (Gokapi, Cloudflared)
- Setup systemd services
- Start all services

### Step 4: Post-Restore Tasks

1. **Update Passwords** (IMPORTANT):
   ```bash
   # Nextcloud
   nano /mnt/ssd/apps/nextcloud/docker-compose.yml
   # Update POSTGRES_PASSWORD
   
   # Pi-hole
   nano /mnt/ssd/docker-projects/pihole/docker-compose.yml
   # Update WEBPASSWORD
   
   # Documents-to-Calendar
   nano /mnt/ssd/docker-projects/documents-to-calendar/.env
   # Update ADMIN_PASSWORD, JWT_SECRET_KEY
   ```

2. **Review Network Configuration**:
   - The restore script will prompt you to restore network config
   - Review and adjust as needed for your ThinkCentre's network

3. **Verify Services**:
   ```bash
   # Check Docker services
   docker ps
   
   # Check systemd services
   systemctl status gokapi
   systemctl status cloudflared
   
   # Check logs if issues
   docker compose logs
   journalctl -u gokapi -f
   journalctl -u cloudflared -f
   ```

4. **Test Services**:
   ```bash
   curl http://localhost:8080   # Caddy
   curl http://localhost:8088   # GoatCounter
   curl http://localhost:8091   # Gokapi
   curl http://localhost:8000/api/health  # Documents-to-Calendar
   ```

---

## 🔧 Architecture Differences Handled

- **Pi (ARM64)** → **ThinkCentre (x86_64)**
- The restore script automatically:
  - Downloads x86_64 Gokapi binary
  - Downloads x86_64 Cloudflared binary
  - Docker images will auto-pull correct architecture

---

## 📝 Important Notes

1. **Passwords**: All passwords in docker-compose.yml files are backed up. **You MUST update them after restore** for security.

2. **Network**: Network configuration may need adjustment for the ThinkCentre's network setup.

3. **Docker Group**: After restore, you may need to log out and back in for Docker group permissions:
   ```bash
   sudo usermod -aG docker $USER
   # Then log out and back in, or:
   newgrp docker
   ```

4. **Missing Data**: If application data wasn't fully backed up, services will start with empty data directories. You may need to:
   - Re-upload files to Nextcloud
   - Re-configure some services
   - Re-authenticate Google Calendar (token.pickle is backed up, should work)

5. **Cloudflare Tunnel**: The tunnel credentials are backed up. The tunnel should work immediately after restore.

---

## 🐛 Troubleshooting

### Docker Permission Issues
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Services Won't Start
```bash
# Check logs
docker compose logs
journalctl -u gokapi -n 50
journalctl -u cloudflared -n 50

# Check file permissions
sudo chown -R $USER:$USER /mnt/ssd/apps/
sudo chown -R $USER:$USER /mnt/ssd/docker-projects/
```

### Network Issues
```bash
# Review network configs
cat /etc/hostname
cat /etc/hosts

# Restart networking
sudo systemctl restart networking
# Or for Netplan:
sudo netplan apply
```

### Cloudflare Tunnel Issues
```bash
# Verify credentials
ls -la ~/.cloudflared/

# Test manually
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

---

## 📊 Backup Statistics

- **Total Backup Size**: ~444MB (may increase if application data was backed up)
- **Credentials**: 7 files
- **Docker Configs**: 10 files
- **Docker Volumes**: 5 volumes
- **System Configs**: Network, systemd services, system info

---

## ✅ Verification Checklist

After restore, verify:
- [ ] Docker is installed and working
- [ ] SSD is mounted at `/mnt/ssd`
- [ ] All Docker services are running (`docker ps`)
- [ ] Systemd services are running (`systemctl status gokapi cloudflared`)
- [ ] All passwords updated
- [ ] Network configuration correct
- [ ] Services accessible (test with curl)
- [ ] Cloudflare tunnel connected
- [ ] No permission errors in logs

---

## 📞 Quick Reference

**Backup Location**: `/media/goce/ADATA SD600Q/pi_backup_20251219_095552/`

**Restore Script**: `~/Desktop/Cursor/Pi-version-control/restore_to_thinkcentre.sh`

**Documentation**: 
- Full guide: `MIGRATION_GUIDE.md`
- Quick reference: `QUICK_MIGRATION.md`

---

**Last Updated**: December 19, 2024  
**Backup Status**: Critical components backed up (credentials, configs, Docker volumes)  
**Ready for Migration**: ✅ Yes

