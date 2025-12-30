#!/bin/bash

###############################################################################
# Pi to ThinkCentre Migration Backup Script
# This script creates a complete backup of your Pi setup for migration
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Backup timestamp
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_BASE_DIR=""

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect backup SSD
detect_backup_ssd() {
    print_info "Detecting backup SSD..."
    
    # Get root device
    ROOT_DEVICE=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    
    # Check all mounted filesystems - parse /proc/mounts for reliability
    while IFS= read -r line; do
        # Parse mount point (second field in /proc/mounts) and decode \040 to spaces
        MOUNT_POINT_RAW=$(echo "$line" | awk '{print $2}')
        MOUNT_POINT=$(echo "$MOUNT_POINT_RAW" | sed 's/\\040/ /g' | sed 's/\\011/\t/g' | sed 's/\\012/\n/g' | sed 's/\\134/\\/g')
        DEVICE=$(echo "$line" | awk '{print $1}')
        FSTYPE=$(echo "$line" | awk '{print $3}')
        
        # Skip root, boot, and system mounts
        if [[ "$MOUNT_POINT" == "/" ]] || \
           [[ "$MOUNT_POINT" == "/boot"* ]] || \
           [[ "$MOUNT_POINT" == "/mnt/ssd" ]] || \
           [[ "$MOUNT_POINT" == "/proc"* ]] || \
           [[ "$MOUNT_POINT" == "/sys"* ]] || \
           [[ "$MOUNT_POINT" == "/dev"* ]] || \
           [[ "$MOUNT_POINT" == "/run"* ]] || \
           [[ "$MOUNT_POINT" == "/tmp"* ]] || \
           [[ "$MOUNT_POINT" == "none" ]]; then
            continue
        fi
        
        # Skip if it's the root device or virtual filesystems
        if [[ "$DEVICE" == "$ROOT_DEVICE"* ]] || \
           [[ "$DEVICE" == "tmpfs" ]] || \
           [[ "$DEVICE" == "devtmpfs" ]] || \
           [[ "$DEVICE" == "zram"* ]] || \
           [[ "$FSTYPE" == "tmpfs" ]] || \
           [[ "$FSTYPE" == "devtmpfs" ]] || \
           [[ "$FSTYPE" == "proc" ]] || \
           [[ "$FSTYPE" == "sysfs" ]]; then
            continue
        fi
        
        # Check if it's writable and has reasonable size (>1GB)
        if [ -d "$MOUNT_POINT" ] && [ -w "$MOUNT_POINT" ] 2>/dev/null; then
            SIZE_GB=$(df -BG "$MOUNT_POINT" 2>/dev/null | tail -1 | awk '{print $2}' | sed 's/G//')
            if [ -n "$SIZE_GB" ] && [ "$SIZE_GB" -gt 1 ] 2>/dev/null; then
                print_success "Found backup SSD: $DEVICE mounted at $MOUNT_POINT"
                BACKUP_BASE_DIR="$MOUNT_POINT/pi_backup_$BACKUP_DATE"
                return 0
            fi
        fi
    done < /proc/mounts
    
    # If no mounted device found, check for unmounted disks
    print_info "Checking for unmounted disks..."
    ROOT_DEVICE_BASE=$(echo "$ROOT_DEVICE" | sed 's|/dev/||')
    for device in $(lsblk -dn -o NAME,TYPE | grep -E "disk|part" | awk '{print "/dev/"$1}'); do
        DEVICE_BASE=$(echo "$device" | sed 's|/dev/||')
        if [[ "$DEVICE_BASE" != "$ROOT_DEVICE_BASE"* ]] && [[ "$DEVICE_BASE" != "mmcblk"* ]] && [[ "$DEVICE_BASE" != "zram"* ]]; then
            # Check if it's not already mounted
            if ! mountpoint -q "$device" 2>/dev/null && ! grep -q "$device" /proc/mounts 2>/dev/null; then
                # Try to mount it
                TEMP_MOUNT="/tmp/backup_check_$$"
                mkdir -p "$TEMP_MOUNT"
                if sudo mount "$device" "$TEMP_MOUNT" 2>/dev/null; then
                    print_success "Found and mounted backup SSD: $device"
                    sudo umount "$TEMP_MOUNT"
                    rmdir "$TEMP_MOUNT"
                    BACKUP_BASE_DIR="/mnt/backup_ssd/pi_backup_$BACKUP_DATE"
                    sudo mkdir -p /mnt/backup_ssd
                    sudo mount "$device" /mnt/backup_ssd
                    return 0
                fi
                rmdir "$TEMP_MOUNT" 2>/dev/null || true
            fi
        fi
    done
    
    print_error "Could not detect backup SSD automatically!"
    print_info "Please mount your backup SSD and specify the mount point:"
    read -p "Backup mount point (e.g., /mnt/backup or /media/goce/ADATA...): " BACKUP_MOUNT
    if [ -d "$BACKUP_MOUNT" ] && [ -w "$BACKUP_MOUNT" ]; then
        BACKUP_BASE_DIR="$BACKUP_MOUNT/pi_backup_$BACKUP_DATE"
    else
        print_error "Invalid mount point or not writable!"
        exit 1
    fi
}

# Function to create backup directory structure
create_backup_structure() {
    print_info "Creating backup directory structure..."
    mkdir -p "$BACKUP_BASE_DIR"/{configs,data,systemd,network,credentials,docker,scripts,manifest}
    print_success "Backup directory created: $BACKUP_BASE_DIR"
}

# Function to backup system information
backup_system_info() {
    print_info "Backing up system information..."
    
    {
        echo "=== System Information ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Backup Date: $(date)"
        echo "User: $(whoami)"
        echo ""
        echo "=== Network Configuration ==="
        echo "IP Addresses:"
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true
        echo ""
        echo "=== Disk Usage ==="
        df -h
        echo ""
        echo "=== Docker Info ==="
        docker --version 2>/dev/null || echo "Docker not installed"
        docker compose version 2>/dev/null || echo "Docker Compose not installed"
    } > "$BACKUP_BASE_DIR/manifest/system_info.txt"
    
    print_success "System information backed up"
}

# Function to backup network configuration
backup_network_config() {
    print_info "Backing up network configuration..."
    
    # Backup network interfaces
    if [ -f /etc/network/interfaces ]; then
        sudo cp /etc/network/interfaces "$BACKUP_BASE_DIR/network/interfaces"
        print_success "Backed up /etc/network/interfaces"
    fi
    
    # Backup Netplan configs (if using Netplan)
    if [ -d /etc/netplan ]; then
        sudo cp -r /etc/netplan "$BACKUP_BASE_DIR/network/netplan"
        print_success "Backed up Netplan configuration"
    fi
    
    # Backup hostname
    if [ -f /etc/hostname ]; then
        sudo cp /etc/hostname "$BACKUP_BASE_DIR/network/hostname"
        print_success "Backed up /etc/hostname"
    fi
    
    # Backup hosts file
    if [ -f /etc/hosts ]; then
        sudo cp /etc/hosts "$BACKUP_BASE_DIR/network/hosts"
        print_success "Backed up /etc/hosts"
    fi
    
    # Backup resolv.conf
    if [ -f /etc/resolv.conf ]; then
        sudo cp /etc/resolv.conf "$BACKUP_BASE_DIR/network/resolv.conf"
        print_success "Backed up /etc/resolv.conf"
    fi
    
    # Backup network manager configs (if using NetworkManager)
    if [ -d /etc/NetworkManager ]; then
        sudo cp -r /etc/NetworkManager "$BACKUP_BASE_DIR/network/NetworkManager"
        print_success "Backed up NetworkManager configuration"
    fi
}

# Function to backup systemd services
backup_systemd_services() {
    print_info "Backing up systemd services..."
    
    # Backup Gokapi service
    if [ -f /etc/systemd/system/gokapi.service ]; then
        sudo cp /etc/systemd/system/gokapi.service "$BACKUP_BASE_DIR/systemd/gokapi.service"
        print_success "Backed up gokapi.service"
    fi
    
    # Backup Cloudflare Tunnel service
    if [ -f /etc/systemd/system/cloudflared.service ]; then
        sudo cp /etc/systemd/system/cloudflared.service "$BACKUP_BASE_DIR/systemd/cloudflared.service"
        print_success "Backed up cloudflared.service"
    fi
    
    # List all custom systemd services
    {
        echo "=== Systemd Services ==="
        systemctl list-unit-files --type=service --state=enabled | grep -E "(gokapi|cloudflared)" || true
    } >> "$BACKUP_BASE_DIR/manifest/system_info.txt"
}

# Function to backup credentials and sensitive data
backup_credentials() {
    print_info "Backing up credentials and sensitive data..."
    
    # Backup Cloudflare tunnel credentials
    if [ -d ~/.cloudflared ]; then
        cp -r ~/.cloudflared "$BACKUP_BASE_DIR/credentials/cloudflared"
        print_success "Backed up Cloudflare tunnel credentials"
    fi
    
    # Backup Gokapi config (contains salts)
    if [ -f /mnt/ssd/apps/gokapi/config/config.json ]; then
        mkdir -p "$BACKUP_BASE_DIR/credentials/gokapi"
        cp /mnt/ssd/apps/gokapi/config/config.json "$BACKUP_BASE_DIR/credentials/gokapi/config.json"
        print_success "Backed up Gokapi config"
    else
        print_warning "Gokapi config not found, skipping"
    fi
    
    # Backup .env files from docker projects
    if [ -d /mnt/ssd/docker-projects ]; then
        find /mnt/ssd/docker-projects -name ".env" -type f 2>/dev/null | while read env_file; do
            REL_PATH=$(echo "$env_file" | sed "s|/mnt/ssd/||")
            mkdir -p "$BACKUP_BASE_DIR/credentials/$(dirname "$REL_PATH")"
            cp "$env_file" "$BACKUP_BASE_DIR/credentials/$REL_PATH"
            print_success "Backed up $env_file"
        done
    fi
    
    # Backup documents-to-calendar credentials
    if [ -d /mnt/ssd/docker-projects/documents-to-calendar/data ]; then
        mkdir -p "$BACKUP_BASE_DIR/credentials/documents-to-calendar"
        cp -r /mnt/ssd/docker-projects/documents-to-calendar/data "$BACKUP_BASE_DIR/credentials/documents-to-calendar/"
        print_success "Backed up documents-to-calendar credentials"
    else
        print_warning "Documents-to-calendar data directory not found, skipping"
    fi
}

# Function to backup Docker configurations
backup_docker_configs() {
    print_info "Backing up Docker configurations..."
    
    # Check if /mnt/ssd exists
    if [ ! -d /mnt/ssd ]; then
        print_warning "/mnt/ssd does not exist, skipping Docker config backup"
        return 0
    fi
    
    # Backup all docker-compose.yml files
    if [ -d /mnt/ssd/docker-projects ]; then
        find /mnt/ssd/docker-projects -name "docker-compose.yml" -type f 2>/dev/null | while read compose_file; do
            REL_PATH=$(echo "$compose_file" | sed "s|/mnt/ssd/||")
            mkdir -p "$BACKUP_BASE_DIR/docker/$(dirname "$REL_PATH")"
            cp "$compose_file" "$BACKUP_BASE_DIR/docker/$REL_PATH"
            print_success "Backed up $compose_file"
        done
    else
        print_warning "/mnt/ssd/docker-projects not found, skipping Docker config backup"
    fi
    
    # Backup Dockerfiles
    find /mnt/ssd/docker-projects -name "Dockerfile" -type f 2>/dev/null | while read dockerfile; do
        REL_PATH=$(echo "$dockerfile" | sed "s|/mnt/ssd/||")
        mkdir -p "$BACKUP_BASE_DIR/docker/$(dirname "$REL_PATH")"
        cp "$dockerfile" "$BACKUP_BASE_DIR/docker/$REL_PATH"
        print_success "Backed up $dockerfile"
    done
    
    # Backup Caddyfile
    if [ -f /mnt/ssd/docker-projects/caddy/config/Caddyfile ]; then
        mkdir -p "$BACKUP_BASE_DIR/docker/caddy/config"
        cp /mnt/ssd/docker-projects/caddy/config/Caddyfile "$BACKUP_BASE_DIR/docker/caddy/config/Caddyfile"
        print_success "Backed up Caddyfile"
    fi
    
    # Backup Docker volumes (named volumes)
    print_info "Backing up Docker named volumes..."
    docker volume ls --format "{{.Name}}" | while read volume_name; do
        if [ -n "$volume_name" ]; then
            print_info "Backing up Docker volume: $volume_name"
            docker run --rm -v "$volume_name":/volume -v "$BACKUP_BASE_DIR/data/docker-volumes":/backup alpine tar czf "/backup/${volume_name}.tar.gz" -C /volume .
            print_success "Backed up volume: $volume_name"
        fi
    done
}

# Function to backup application data
backup_application_data() {
    print_info "Backing up application data..."
    
    # Check if /mnt/ssd exists
    if [ ! -d /mnt/ssd ]; then
        print_warning "/mnt/ssd does not exist, skipping application data backup"
        return 0
    fi
    
    # Backup Nextcloud data
    if [ -d /mnt/ssd/apps/nextcloud ] && [ "$(ls -A /mnt/ssd/apps/nextcloud 2>/dev/null)" ]; then
        print_info "Backing up Nextcloud data (this may take a while)..."
        sudo tar czf "$BACKUP_BASE_DIR/data/nextcloud.tar.gz" -C /mnt/ssd/apps/nextcloud .
        print_success "Backed up Nextcloud data"
    else
        print_warning "Nextcloud data directory not found or empty, skipping"
    fi
    
    # Backup Gokapi data
    if [ -d /mnt/ssd/apps/gokapi-data ] && [ "$(ls -A /mnt/ssd/apps/gokapi-data 2>/dev/null)" ]; then
        print_info "Backing up Gokapi data..."
        sudo tar czf "$BACKUP_BASE_DIR/data/gokapi-data.tar.gz" -C /mnt/ssd/apps/gokapi-data .
        print_success "Backed up Gokapi data"
    else
        print_warning "Gokapi data directory not found or empty, skipping"
    fi
    
    # Backup GoatCounter data
    if [ -d /mnt/ssd/docker-projects/goatcounter/goatcounter-data ] && [ "$(ls -A /mnt/ssd/docker-projects/goatcounter/goatcounter-data 2>/dev/null)" ]; then
        print_info "Backing up GoatCounter data..."
        sudo tar czf "$BACKUP_BASE_DIR/data/goatcounter-data.tar.gz" -C /mnt/ssd/docker-projects/goatcounter/goatcounter-data .
        print_success "Backed up GoatCounter data"
    else
        print_warning "GoatCounter data directory not found or empty, skipping"
    fi
    
    # Backup Uptime Kuma data
    if [ -d /mnt/ssd/docker-projects/uptime-kuma/data ] && [ "$(ls -A /mnt/ssd/docker-projects/uptime-kuma/data 2>/dev/null)" ]; then
        print_info "Backing up Uptime Kuma data..."
        sudo tar czf "$BACKUP_BASE_DIR/data/uptime-kuma-data.tar.gz" -C /mnt/ssd/docker-projects/uptime-kuma/data .
        print_success "Backed up Uptime Kuma data"
    else
        print_warning "Uptime Kuma data directory not found or empty, skipping"
    fi
    
    # Backup Documents-to-Calendar data
    if [ -d /mnt/ssd/docker-projects/documents-to-calendar ]; then
        print_info "Backing up Documents-to-Calendar data..."
        cd /mnt/ssd/docker-projects/documents-to-calendar
        if [ -n "$(ls -A uploads temp data documents_calendar.db 2>/dev/null)" ]; then
            sudo tar czf "$BACKUP_BASE_DIR/data/documents-to-calendar.tar.gz" \
                --exclude='backend' --exclude='frontend' \
                uploads temp data documents_calendar.db 2>/dev/null || true
            print_success "Backed up Documents-to-Calendar data"
        else
            print_warning "Documents-to-Calendar data directory empty, skipping"
        fi
    else
        print_warning "Documents-to-Calendar directory not found, skipping"
    fi
    
    # Backup Caddy data
    if [ -d /mnt/ssd/docker-projects/caddy/data ] && [ "$(ls -A /mnt/ssd/docker-projects/caddy/data 2>/dev/null)" ]; then
        print_info "Backing up Caddy data..."
        sudo tar czf "$BACKUP_BASE_DIR/data/caddy-data.tar.gz" -C /mnt/ssd/docker-projects/caddy/data .
        print_success "Backed up Caddy data"
    else
        print_warning "Caddy data directory not found or empty, skipping"
    fi
    
    # Backup Caddy site files
    if [ -d /mnt/ssd/docker-projects/caddy/site ] && [ "$(ls -A /mnt/ssd/docker-projects/caddy/site 2>/dev/null)" ]; then
        print_info "Backing up Caddy site files..."
        sudo tar czf "$BACKUP_BASE_DIR/data/caddy-site.tar.gz" -C /mnt/ssd/docker-projects/caddy/site .
        print_success "Backed up Caddy site files"
    else
        print_warning "Caddy site directory not found or empty, skipping"
    fi
}

# Function to backup configuration repository
backup_config_repo() {
    print_info "Backing up configuration repository..."
    
    # Backup the Pi-version-control directory
    if [ -d ~/Desktop/Cursor/Pi-version-control ]; then
        tar czf "$BACKUP_BASE_DIR/configs/pi-version-control-repo.tar.gz" \
            -C ~/Desktop/Cursor Pi-version-control
        print_success "Backed up configuration repository"
    fi
}

# Function to backup Gokapi binary info (for architecture replacement)
backup_binary_info() {
    print_info "Documenting binary information for architecture migration..."
    
    {
        echo "=== Binary Information ==="
        echo "Current Architecture: $(uname -m)"
        echo ""
        echo "=== Gokapi Binary ==="
        if [ -f /mnt/ssd/apps/gokapi/gokapi ]; then
            echo "Location: /mnt/ssd/apps/gokapi/gokapi"
            echo "Size: $(stat -c%s /mnt/ssd/apps/gokapi/gokapi) bytes"
            file /mnt/ssd/apps/gokapi/gokapi || true
        else
            echo "Gokapi binary not found"
        fi
        echo ""
        echo "=== Cloudflared Binary ==="
        if command -v cloudflared &> /dev/null; then
            echo "Location: $(which cloudflared)"
            echo "Version: $(cloudflared --version 2>/dev/null || echo 'unknown')"
        else
            echo "Cloudflared not found in PATH"
        fi
        echo ""
        echo "=== Download URLs for x86_64 ==="
        echo "Gokapi: https://github.com/Forceu/Gokapi/releases/latest/download/gokapi-linux-amd64"
        echo "Cloudflared: https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    } > "$BACKUP_BASE_DIR/manifest/binary_info.txt"
    
    print_success "Binary information documented"
}

# Function to create backup manifest
create_backup_manifest() {
    print_info "Creating backup manifest..."
    
    {
        echo "=== Backup Manifest ==="
        echo "Backup Date: $(date)"
        echo "Source System: $(hostname)"
        echo "Backup Location: $BACKUP_BASE_DIR"
        echo ""
        echo "=== Directory Structure ==="
        find "$BACKUP_BASE_DIR" -type f | sort
        echo ""
        echo "=== Backup Sizes ==="
        du -sh "$BACKUP_BASE_DIR"/*
    } > "$BACKUP_BASE_DIR/manifest/backup_manifest.txt"
    
    print_success "Backup manifest created"
}

# Function to verify backup
verify_backup() {
    print_info "Verifying backup integrity..."
    
    # Check critical files
    CRITICAL_FILES=(
        "manifest/system_info.txt"
        "manifest/backup_manifest.txt"
        "network/hostname"
        "systemd/gokapi.service"
        "systemd/cloudflared.service"
        "credentials/cloudflared/config.yml"
    )
    
    MISSING_FILES=()
    for file in "${CRITICAL_FILES[@]}"; do
        if [ ! -f "$BACKUP_BASE_DIR/$file" ]; then
            MISSING_FILES+=("$file")
        fi
    done
    
    if [ ${#MISSING_FILES[@]} -eq 0 ]; then
        print_success "Backup verification passed!"
    else
        print_warning "Some critical files are missing:"
        for file in "${MISSING_FILES[@]}"; do
            echo "  - $file"
        done
    fi
}

# Main execution
main() {
    echo "=========================================="
    echo "Pi to ThinkCentre Migration Backup"
    echo "=========================================="
    echo ""
    
    # Check if running as root (we'll use sudo where needed)
    if [ "$EUID" -eq 0 ]; then
        print_error "Please run this script as a regular user (not root)"
        exit 1
    fi
    
    # Detect backup SSD
    detect_backup_ssd
    
    # Create backup structure
    create_backup_structure
    
    # Perform backups
    backup_system_info
    backup_network_config
    backup_systemd_services
    backup_credentials
    backup_docker_configs
    backup_application_data
    backup_config_repo
    backup_binary_info
    
    # Create manifest
    create_backup_manifest
    
    # Verify backup
    verify_backup
    
    # Summary
    echo ""
    echo "=========================================="
    print_success "Backup completed successfully!"
    echo "=========================================="
    echo ""
    echo "Backup location: $BACKUP_BASE_DIR"
    echo "Total size: $(du -sh "$BACKUP_BASE_DIR" | cut -f1)"
    echo ""
    echo "Next steps:"
    echo "1. Safely remove the backup SSD"
    echo "2. Transfer it to your ThinkCentre"
    echo "3. Run the restore script on the ThinkCentre"
    echo ""
}

# Run main function
main

