# Pi to ThinkCentre Migration Guide

This guide explains how to backup your Raspberry Pi setup and restore it on a Lenovo ThinkCentre running Debian Trixie.

## Overview

The migration process consists of two main steps:
1. **Backup** - Create a complete backup on your Pi
2. **Restore** - Restore the backup on your ThinkCentre

## Prerequisites

### On Raspberry Pi (Backup)
- Raspberry Pi with all services running
- Backup SSD inserted and detected
- Sufficient space on backup SSD (check with `df -h`)
- SSH access or direct terminal access

### On ThinkCentre (Restore)
- Debian Trixie installed
- Backup SSD with backup data
- Internet connection (for downloading dependencies)
- SSH access or direct terminal access
- User with sudo privileges

## Step 1: Backup on Raspberry Pi

### 1.1 Prepare Backup SSD

Insert your backup SSD into the Pi. The script will automatically detect it, but you can also manually mount it:

```bash
# Find your SSD
lsblk

# Mount it (replace /dev/sdX1 with your device)
sudo mkdir -p /mnt/backup_ssd
sudo mount /dev/sdX1 /mnt/backup_ssd
```

### 1.2 Run Backup Script

```bash
cd ~/Desktop/Cursor/Pi-version-control
./backup_pi.sh
```

The script will:
- Auto-detect your backup SSD
- Create a timestamped backup directory
- Backup all configurations
- Backup all application data
- Backup Docker volumes
- Backup credentials and sensitive data
- Backup network configuration
- Create a manifest of everything backed up

### 1.3 Verify Backup

After the backup completes, check the backup directory:

```bash
# The backup location will be shown at the end
# Usually something like: /mnt/backup_ssd/pi_backup_YYYYMMDD_HHMMSS

# Check backup size
du -sh /mnt/backup_ssd/pi_backup_*

# List backup contents
ls -la /mnt/backup_ssd/pi_backup_*/
```

### 1.4 Safely Remove Backup SSD

```bash
# Unmount the SSD
sudo umount /mnt/backup_ssd

# Safely remove
```

## Step 2: Restore on ThinkCentre

### 2.1 Prepare ThinkCentre

1. **Install Debian Trixie** (if not already installed)
2. **Create a user account** (if needed)
3. **Insert the backup SSD**

### 2.2 Mount Backup SSD

The restore script will try to auto-detect the backup, but you can manually mount it:

```bash
# Find your SSD
lsblk

# Mount it
sudo mkdir -p /mnt/backup_ssd
sudo mount /dev/sdX1 /mnt/backup_ssd
```

### 2.3 Transfer Backup Scripts (Optional)

If you want to use the restore script from the backup, you can copy it:

```bash
# Copy restore script from backup
cp /mnt/backup_ssd/pi_backup_*/configs/pi-version-control-repo.tar.gz ~/
cd ~
tar xzf pi-version-control-repo.tar.gz
cd Pi-version-control
```

Or download/clone the repository on the ThinkCentre.

### 2.4 Run Restore Script

```bash
cd ~/Desktop/Cursor/Pi-version-control
./restore_to_thinkcentre.sh
```

The script will:
- Auto-detect the backup directory
- Install Docker and Docker Compose
- Setup SSD mount at `/mnt/ssd`
- Restore all configurations
- Restore all application data
- Restore Docker volumes
- Restore credentials
- Download x86_64 binaries (Gokapi, Cloudflared)
- Setup systemd services
- Start all services

### 2.5 Post-Restore Steps

#### 2.5.1 Review Network Configuration

The restore script will prompt you to restore network configuration. Review and update:

```bash
# Check current network settings
ip addr show
hostname

# If you restored network configs, you may need to:
sudo systemctl restart networking
# Or for Netplan:
sudo netplan apply
```

#### 2.5.2 Update Passwords

**Important**: Update all passwords in docker-compose.yml files:

```bash
# Nextcloud
nano /mnt/ssd/apps/nextcloud/docker-compose.yml
# Update POSTGRES_PASSWORD

# Pi-hole
nano /mnt/ssd/docker-projects/pihole/docker-compose.yml
# Update WEBPASSWORD

# TravelSync
nano /mnt/ssd/docker-projects/travelsync/.env
# Update ADMIN_PASSWORD, JWT_SECRET_KEY
```

#### 2.5.3 Verify Services

```bash
# Check Docker services
docker ps

# Check systemd services
systemctl status gokapi
systemctl status cloudflared

# Check service logs
docker compose -f /mnt/ssd/docker-projects/caddy/docker-compose.yml logs
journalctl -u gokapi -f
journalctl -u cloudflared -f
```

#### 2.5.4 Test Services

Test each service:

```bash
# Caddy
curl http://localhost:8080

# GoatCounter
curl http://localhost:8088

# Nextcloud
curl http://localhost:8081

# Gokapi
curl http://localhost:8091

# TravelSync
curl http://localhost:8000/api/health

# Uptime Kuma
curl http://localhost:3001
```

#### 2.5.5 Docker Group (if needed)

If you get permission errors with Docker:

```bash
# Add user to docker group (if not already)
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker
```

## What Gets Backed Up

### Configurations
- Docker Compose files
- Dockerfiles
- Caddyfile
- Systemd service files
- Network configuration files

### Data
- Nextcloud data (`/mnt/ssd/apps/nextcloud`)
- Gokapi data (`/mnt/ssd/apps/gokapi-data`)
- GoatCounter data
- Uptime Kuma data
- TravelSync data (uploads, database, credentials)
- Caddy data and site files
- Docker named volumes

### Credentials
- Cloudflare tunnel credentials (`~/.cloudflared/`)
- Gokapi config with salts
- `.env` files from all projects
- Google Calendar tokens and credentials

### System
- Network interfaces configuration
- Hostname
- Hosts file
- Systemd service configurations

## Architecture Differences

The Pi uses ARM64 architecture, while the ThinkCentre uses x86_64. The restore script handles this by:

1. **Not backing up binaries** - ARM64 binaries won't work on x86_64
2. **Downloading correct binaries** - Restore script downloads x86_64 versions:
   - Gokapi: Downloads `gokapi-linux-amd64`
   - Cloudflared: Downloads `cloudflared-linux-amd64.deb`
3. **Docker images** - Docker will automatically pull the correct architecture images

## Troubleshooting

### Backup Issues

**Problem**: Script can't detect backup SSD
```bash
# Manually mount and specify path
sudo mount /dev/sdX1 /mnt/backup
# When prompted, enter: /mnt/backup
```

**Problem**: Permission denied errors
```bash
# Ensure you're running as regular user (not root)
# Check SSD mount permissions
ls -la /mnt/backup_ssd
```

**Problem**: Out of space
```bash
# Check available space
df -h
# Clean up old backups if needed
```

### Restore Issues

**Problem**: Docker permission denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

**Problem**: Services won't start
```bash
# Check logs
docker compose logs
journalctl -u gokapi -n 50
journalctl -u cloudflared -n 50

# Check file permissions
ls -la /mnt/ssd/apps/
sudo chown -R $USER:$USER /mnt/ssd/apps/
```

**Problem**: Network configuration issues
```bash
# Review restored network files
cat /etc/network/interfaces
cat /etc/hostname

# Restart networking
sudo systemctl restart networking
```

**Problem**: Cloudflare tunnel won't start
```bash
# Verify credentials file exists
ls -la ~/.cloudflared/

# Test tunnel manually
cloudflared tunnel --config ~/.cloudflared/config.yml run
```

**Problem**: Gokapi won't start
```bash
# Check binary permissions
ls -la /mnt/ssd/apps/gokapi/gokapi
chmod +x /mnt/ssd/apps/gokapi/gokapi

# Check config file
cat /mnt/ssd/apps/gokapi/config/config.json

# Check service status
systemctl status gokapi
journalctl -u gokapi -f
```

## Backup Structure

The backup creates the following structure:

```
pi_backup_YYYYMMDD_HHMMSS/
├── configs/
│   └── pi-version-control-repo.tar.gz
├── credentials/
│   ├── cloudflared/
│   ├── gokapi/
│   ├── travelsync/
│   └── .env files
├── data/
│   ├── nextcloud.tar.gz
│   ├── gokapi-data.tar.gz
│   ├── goatcounter-data.tar.gz
│   ├── uptime-kuma-data.tar.gz
│   ├── travelsync.tar.gz
│   ├── caddy-data.tar.gz
│   ├── caddy-site.tar.gz
│   └── docker-volumes/
├── docker/
│   ├── caddy/
│   ├── goatcounter/
│   ├── nextcloud/
│   ├── uptime-kuma/
│   ├── travelsync/
│   └── pihole/
├── network/
│   ├── interfaces
│   ├── hostname
│   ├── hosts
│   └── resolv.conf
├── systemd/
│   ├── gokapi.service
│   └── cloudflared.service
├── manifest/
│   ├── system_info.txt
│   ├── binary_info.txt
│   └── backup_manifest.txt
└── scripts/
    └── (backup/restore scripts)
```

## Security Notes

1. **Passwords**: All passwords in docker-compose.yml files are backed up. Update them after restore.

2. **Credentials**: Sensitive credentials are included in the backup. Keep the backup SSD secure.

3. **Permissions**: The backup includes files with sensitive permissions. The restore script attempts to restore these, but verify after restore.

4. **Network**: Network configuration may need adjustment for the new machine's network setup.

## Rollback Plan

If something goes wrong during restore:

1. **Stop all services**:
   ```bash
   docker compose -f /mnt/ssd/docker-projects/*/docker-compose.yml down
   sudo systemctl stop gokapi cloudflared
   ```

2. **Review logs** to identify issues

3. **Fix configuration** files as needed

4. **Restart services** one by one

5. **If needed**, you can re-run the restore script (it's mostly idempotent)

## Support

If you encounter issues:

1. Check the manifest files in the backup for system information
2. Review service logs
3. Verify file permissions
4. Check network connectivity
5. Ensure all dependencies are installed

## Summary Checklist

### Backup (on Pi)
- [ ] Backup SSD inserted
- [ ] Backup script executed successfully
- [ ] Backup verified (check manifest)
- [ ] Backup size reasonable
- [ ] SSD safely unmounted

### Restore (on ThinkCentre)
- [ ] Debian Trixie installed
- [ ] Backup SSD mounted
- [ ] Restore script executed successfully
- [ ] Docker and Docker Compose installed
- [ ] SSD mounted at `/mnt/ssd`
- [ ] All configurations restored
- [ ] All data restored
- [ ] Credentials restored
- [ ] Services started
- [ ] Network configuration reviewed
- [ ] Passwords updated
- [ ] Services tested and working

---

**Last Updated**: December 2024
**Tested On**: Raspberry Pi (ARM64) → Lenovo ThinkCentre (x86_64)
**OS**: Debian Trixie

