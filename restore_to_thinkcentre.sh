#!/bin/bash

###############################################################################
# Pi to ThinkCentre Migration Restore Script
# This script restores a Pi backup on a Debian Trixie ThinkCentre
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BACKUP_DIR=""
RESTORE_USER=""

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

# Function to detect backup directory
detect_backup_dir() {
    print_info "Detecting backup directory..."
    
    # Check common mount points
    MOUNT_POINTS=("/mnt" "/media" "/mnt/backup_ssd")
    
    for mount_point in "${MOUNT_POINTS[@]}"; do
        if [ -d "$mount_point" ]; then
            BACKUP_CANDIDATES=$(find "$mount_point" -maxdepth 2 -type d -name "pi_backup_*" 2>/dev/null)
            if [ -n "$BACKUP_CANDIDATES" ]; then
                # Use the most recent backup
                BACKUP_DIR=$(echo "$BACKUP_CANDIDATES" | sort -r | head -1)
                print_success "Found backup: $BACKUP_DIR"
                return 0
            fi
        fi
    done
    
    # If not found, ask user
    print_warning "Could not auto-detect backup directory"
    read -p "Enter full path to backup directory: " BACKUP_DIR
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "Backup directory does not exist: $BACKUP_DIR"
        exit 1
    fi
    
    if [ ! -f "$BACKUP_DIR/manifest/backup_manifest.txt" ]; then
        print_error "Invalid backup directory (missing manifest)"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if running as regular user
    if [ "$EUID" -eq 0 ]; then
        print_error "Please run this script as a regular user (not root)"
        exit 1
    fi
    
    RESTORE_USER=$(whoami)
    
    # Check OS
    if [ ! -f /etc/os-release ]; then
        print_error "Cannot determine OS version"
        exit 1
    fi
    
    OS_NAME=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    if [ "$OS_NAME" != "debian" ]; then
        print_warning "Expected Debian, found: $OS_NAME"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        print_warning "Expected x86_64 architecture, found: $ARCH"
        print_warning "Some binaries may need manual installation"
    fi
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. It will be installed during restore."
    fi
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        print_warning "User $RESTORE_USER is not in docker group"
        print_info "Will add user to docker group during setup"
    fi
    
    print_success "Prerequisites check completed"
}

# Function to install system dependencies
install_dependencies() {
    print_info "Installing system dependencies..."
    
    # Update package list
    sudo apt update
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        print_info "Installing Docker..."
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sudo sh /tmp/get-docker.sh
        sudo usermod -aG docker "$RESTORE_USER"
        print_success "Docker installed"
        print_warning "You may need to log out and back in for docker group to take effect"
    else
        print_success "Docker already installed"
    fi
    
    # Install Docker Compose plugin
    if ! docker compose version &> /dev/null; then
        print_info "Installing Docker Compose plugin..."
        sudo apt-get install -y docker-compose-plugin
        print_success "Docker Compose installed"
    else
        print_success "Docker Compose already installed"
    fi
    
    # Install other utilities
    sudo apt-get install -y wget curl tar gzip
    
    print_success "Dependencies installed"
}

# Function to setup SSD mount
setup_ssd_mount() {
    print_info "Setting up SSD mount..."
    
    # Check if /mnt/ssd exists and is mounted
    if mountpoint -q /mnt/ssd 2>/dev/null; then
        print_success "/mnt/ssd is already mounted"
        return 0
    fi
    
    # Check if /mnt/ssd directory exists
    if [ ! -d /mnt/ssd ]; then
        sudo mkdir -p /mnt/ssd
    fi
    
    # Try to find and mount SSD
    print_info "Looking for SSD to mount at /mnt/ssd..."
    ROOT_DEVICE=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    
    for device in $(lsblk -dn -o NAME,TYPE | grep disk | awk '{print "/dev/"$1}'); do
        if [[ "$device" != "$ROOT_DEVICE"* ]]; then
            PARTITIONS=$(lsblk -dn -o NAME "$device" | grep -E '[0-9]$' || true)
            if [ -n "$PARTITIONS" ]; then
                PARTITION=$(lsblk -dn -o NAME "$device" | grep -E '[0-9]$' | head -1)
                DEVICE_PATH="/dev/$PARTITION"
                
                # Try to mount
                if sudo mount "$DEVICE_PATH" /mnt/ssd 2>/dev/null; then
                    print_success "Mounted $DEVICE_PATH to /mnt/ssd"
                    
                    # Add to fstab if not already there
                    if ! grep -q "/mnt/ssd" /etc/fstab; then
                        UUID=$(blkid -s UUID -o value "$DEVICE_PATH")
                        FSTYPE=$(blkid -s TYPE -o value "$DEVICE_PATH")
                        echo "UUID=$UUID /mnt/ssd $FSTYPE defaults 0 2" | sudo tee -a /etc/fstab
                        print_success "Added to /etc/fstab"
                    fi
                    return 0
                fi
            fi
        fi
    done
    
    print_warning "Could not auto-mount SSD. Please mount it manually:"
    print_info "  sudo mount /dev/sdX1 /mnt/ssd"
    print_info "  Then add to /etc/fstab for permanent mounting"
    read -p "Press Enter after mounting SSD, or 's' to skip: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_warning "Skipping SSD mount. You'll need to mount it manually later."
        return 0
    fi
}

# Function to restore network configuration
restore_network_config() {
    print_info "Restoring network configuration..."
    
    if [ ! -d "$BACKUP_DIR/network" ]; then
        print_warning "Network config backup not found, skipping..."
        return 0
    fi
    
    print_warning "Network configuration restoration requires manual review"
    print_info "Backed up network files are in: $BACKUP_DIR/network"
    print_info "Please review and apply network settings manually:"
    echo "  - /etc/network/interfaces (if using ifupdown)"
    echo "  - /etc/netplan/*.yaml (if using Netplan)"
    echo "  - /etc/hostname"
    echo "  - /etc/hosts"
    echo ""
    read -p "Copy network files now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$BACKUP_DIR/network/hostname" ]; then
            sudo cp "$BACKUP_DIR/network/hostname" /etc/hostname
            print_success "Restored hostname"
        fi
        
        if [ -f "$BACKUP_DIR/network/hosts" ]; then
            sudo cp "$BACKUP_DIR/network/hosts" /etc/hosts
            print_success "Restored hosts file"
        fi
        
        if [ -f "$BACKUP_DIR/network/interfaces" ]; then
            sudo cp "$BACKUP_DIR/network/interfaces" /etc/network/interfaces
            print_success "Restored network interfaces"
        fi
        
        if [ -d "$BACKUP_DIR/network/netplan" ]; then
            sudo cp -r "$BACKUP_DIR/network/netplan"/* /etc/netplan/
            print_success "Restored Netplan configuration"
        fi
    fi
}

# Function to create directory structure
create_directory_structure() {
    print_info "Creating directory structure..."
    
    # Create Docker project directories
    sudo mkdir -p /mnt/ssd/docker-projects/{caddy,goatcounter,uptime-kuma,documents-to-calendar,pihole}
    sudo mkdir -p /mnt/ssd/apps/{nextcloud,gokapi,gokapi-data,gokapi-config}
    
    # Set ownership
    sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/docker-projects
    sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/apps
    
    print_success "Directory structure created"
}

# Function to restore Docker configurations
restore_docker_configs() {
    print_info "Restoring Docker configurations..."
    
    if [ ! -d "$BACKUP_DIR/docker" ]; then
        print_warning "Docker config backup not found"
        return 0
    fi
    
    # Restore docker-compose files
    find "$BACKUP_DIR/docker" -name "docker-compose.yml" -type f | while read compose_file; do
        REL_PATH=$(echo "$compose_file" | sed "s|$BACKUP_DIR/docker/||")
        TARGET_DIR="/mnt/ssd/$(dirname "$REL_PATH")"
        mkdir -p "$TARGET_DIR"
        cp "$compose_file" "$TARGET_DIR/docker-compose.yml"
        print_success "Restored $REL_PATH"
    done
    
    # Restore Dockerfiles
    find "$BACKUP_DIR/docker" -name "Dockerfile" -type f | while read dockerfile; do
        REL_PATH=$(echo "$dockerfile" | sed "s|$BACKUP_DIR/docker/||")
        TARGET_DIR="/mnt/ssd/$(dirname "$REL_PATH")"
        mkdir -p "$TARGET_DIR"
        cp "$dockerfile" "$TARGET_DIR/Dockerfile"
        print_success "Restored $REL_PATH"
    done
    
    # Restore Caddyfile
    if [ -f "$BACKUP_DIR/docker/caddy/config/Caddyfile" ]; then
        mkdir -p /mnt/ssd/docker-projects/caddy/config
        cp "$BACKUP_DIR/docker/caddy/config/Caddyfile" /mnt/ssd/docker-projects/caddy/config/Caddyfile
        print_success "Restored Caddyfile"
    fi
    
    print_success "Docker configurations restored"
}

# Function to restore Docker volumes
restore_docker_volumes() {
    print_info "Restoring Docker named volumes..."
    
    if [ ! -d "$BACKUP_DIR/data/docker-volumes" ]; then
        print_warning "No Docker volumes backup found"
        return 0
    fi
    
    for volume_backup in "$BACKUP_DIR/data/docker-volumes"/*.tar.gz; do
        if [ -f "$volume_backup" ]; then
            VOLUME_NAME=$(basename "$volume_backup" .tar.gz)
            print_info "Restoring volume: $VOLUME_NAME"
            
            # Create volume if it doesn't exist
            docker volume create "$VOLUME_NAME" 2>/dev/null || true
            
            # Restore volume
            docker run --rm -v "$VOLUME_NAME":/volume -v "$(dirname "$volume_backup")":/backup alpine \
                sh -c "cd /volume && tar xzf /backup/$(basename "$volume_backup")"
            
            print_success "Restored volume: $VOLUME_NAME"
        fi
    done
}

# Function to restore application data
restore_application_data() {
    print_info "Restoring application data..."
    
    # Restore Nextcloud
    if [ -f "$BACKUP_DIR/data/nextcloud.tar.gz" ]; then
        print_info "Restoring Nextcloud data..."
        sudo tar xzf "$BACKUP_DIR/data/nextcloud.tar.gz" -C /mnt/ssd/apps/nextcloud
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/apps/nextcloud
        print_success "Nextcloud data restored"
    fi
    
    # Restore Gokapi data
    if [ -f "$BACKUP_DIR/data/gokapi-data.tar.gz" ]; then
        print_info "Restoring Gokapi data..."
        sudo tar xzf "$BACKUP_DIR/data/gokapi-data.tar.gz" -C /mnt/ssd/apps/gokapi-data
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/apps/gokapi-data
        print_success "Gokapi data restored"
    fi
    
    # Restore GoatCounter data
    if [ -f "$BACKUP_DIR/data/goatcounter-data.tar.gz" ]; then
        print_info "Restoring GoatCounter data..."
        mkdir -p /mnt/ssd/docker-projects/goatcounter/goatcounter-data
        sudo tar xzf "$BACKUP_DIR/data/goatcounter-data.tar.gz" -C /mnt/ssd/docker-projects/goatcounter/goatcounter-data
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/docker-projects/goatcounter/goatcounter-data
        print_success "GoatCounter data restored"
    fi
    
    # Restore Uptime Kuma data
    if [ -f "$BACKUP_DIR/data/uptime-kuma-data.tar.gz" ]; then
        print_info "Restoring Uptime Kuma data..."
        mkdir -p /mnt/ssd/docker-projects/uptime-kuma/data
        sudo tar xzf "$BACKUP_DIR/data/uptime-kuma-data.tar.gz" -C /mnt/ssd/docker-projects/uptime-kuma/data
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/docker-projects/uptime-kuma/data
        print_success "Uptime Kuma data restored"
    fi
    
    # Restore Documents-to-Calendar data
    if [ -f "$BACKUP_DIR/data/documents-to-calendar.tar.gz" ]; then
        print_info "Restoring Documents-to-Calendar data..."
        mkdir -p /mnt/ssd/docker-projects/documents-to-calendar
        sudo tar xzf "$BACKUP_DIR/data/documents-to-calendar.tar.gz" -C /mnt/ssd/docker-projects/documents-to-calendar
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/docker-projects/documents-to-calendar
        print_success "Documents-to-Calendar data restored"
    fi
    
    # Restore Caddy data
    if [ -f "$BACKUP_DIR/data/caddy-data.tar.gz" ]; then
        print_info "Restoring Caddy data..."
        mkdir -p /mnt/ssd/docker-projects/caddy/data
        sudo tar xzf "$BACKUP_DIR/data/caddy-data.tar.gz" -C /mnt/ssd/docker-projects/caddy/data
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/docker-projects/caddy/data
        print_success "Caddy data restored"
    fi
    
    # Restore Caddy site files
    if [ -f "$BACKUP_DIR/data/caddy-site.tar.gz" ]; then
        print_info "Restoring Caddy site files..."
        mkdir -p /mnt/ssd/docker-projects/caddy/site
        sudo tar xzf "$BACKUP_DIR/data/caddy-site.tar.gz" -C /mnt/ssd/docker-projects/caddy/site
        sudo chown -R "$RESTORE_USER:$RESTORE_USER" /mnt/ssd/docker-projects/caddy/site
        print_success "Caddy site files restored"
    fi
}

# Function to restore credentials
restore_credentials() {
    print_info "Restoring credentials and sensitive data..."
    
    # Restore Cloudflare tunnel credentials
    if [ -d "$BACKUP_DIR/credentials/cloudflared" ]; then
        mkdir -p ~/.cloudflared
        cp -r "$BACKUP_DIR/credentials/cloudflared"/* ~/.cloudflared/
        chmod 600 ~/.cloudflared/*.json 2>/dev/null || true
        print_success "Cloudflare tunnel credentials restored"
    fi
    
    # Restore Gokapi config
    if [ -f "$BACKUP_DIR/credentials/gokapi/config.json" ]; then
        mkdir -p /mnt/ssd/apps/gokapi/config
        cp "$BACKUP_DIR/credentials/gokapi/config.json" /mnt/ssd/apps/gokapi/config/config.json
        print_success "Gokapi config restored"
    fi
    
    # Restore .env files
    find "$BACKUP_DIR/credentials" -name ".env" -type f | while read env_file; do
        REL_PATH=$(echo "$env_file" | sed "s|$BACKUP_DIR/credentials/||")
        TARGET_PATH="/mnt/ssd/$REL_PATH"
        mkdir -p "$(dirname "$TARGET_PATH")"
        cp "$env_file" "$TARGET_PATH"
        chmod 600 "$TARGET_PATH"
        print_success "Restored $REL_PATH"
    done
    
    # Restore documents-to-calendar credentials
    if [ -d "$BACKUP_DIR/credentials/documents-to-calendar/data" ]; then
        mkdir -p /mnt/ssd/docker-projects/documents-to-calendar/data
        cp -r "$BACKUP_DIR/credentials/documents-to-calendar/data"/* \
            /mnt/ssd/docker-projects/documents-to-calendar/data/
        print_success "Documents-to-Calendar credentials restored"
    fi
    
    print_success "Credentials restored"
}

# Function to install and setup Gokapi
setup_gokapi() {
    print_info "Setting up Gokapi..."
    
    # Download x86_64 binary
    print_info "Downloading Gokapi for x86_64..."
    cd /mnt/ssd/apps/gokapi
    wget -q https://github.com/Forceu/Gokapi/releases/latest/download/gokapi-linux-amd64 -O gokapi
    chmod +x gokapi
    print_success "Gokapi binary downloaded"
    
    # Restore systemd service
    if [ -f "$BACKUP_DIR/systemd/gokapi.service" ]; then
        sudo cp "$BACKUP_DIR/systemd/gokapi.service" /etc/systemd/system/gokapi.service
        # Update user in service file
        sudo sed -i "s/User=.*/User=$RESTORE_USER/" /etc/systemd/system/gokapi.service
        sudo systemctl daemon-reload
        sudo systemctl enable gokapi.service
        print_success "Gokapi systemd service installed"
    fi
}

# Function to install and setup Cloudflare Tunnel
setup_cloudflared() {
    print_info "Setting up Cloudflare Tunnel..."
    
    # Download and install cloudflared for x86_64
    if ! command -v cloudflared &> /dev/null; then
        print_info "Downloading Cloudflared for x86_64..."
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb
        sudo dpkg -i /tmp/cloudflared.deb || sudo apt-get install -f -y
        print_success "Cloudflared installed"
    else
        print_success "Cloudflared already installed"
    fi
    
    # Restore systemd service
    if [ -f "$BACKUP_DIR/systemd/cloudflared.service" ]; then
        sudo cp "$BACKUP_DIR/systemd/cloudflared.service" /etc/systemd/system/cloudflared.service
        # Update user in service file
        sudo sed -i "s/User=.*/User=$RESTORE_USER/" /etc/systemd/system/cloudflared.service
        sudo systemctl daemon-reload
        sudo systemctl enable cloudflared.service
        print_success "Cloudflared systemd service installed"
    fi
}

# Function to restore configuration repository
restore_config_repo() {
    print_info "Restoring configuration repository..."
    
    if [ -f "$BACKUP_DIR/configs/pi-version-control-repo.tar.gz" ]; then
        cd ~/Desktop/Cursor 2>/dev/null || mkdir -p ~/Desktop/Cursor && cd ~/Desktop/Cursor
        tar xzf "$BACKUP_DIR/configs/pi-version-control-repo.tar.gz"
        print_success "Configuration repository restored"
    fi
}

# Function to start Docker services
start_docker_services() {
    print_info "Starting Docker services..."
    
    # Start Caddy
    if [ -f /mnt/ssd/docker-projects/caddy/docker-compose.yml ]; then
        print_info "Starting Caddy..."
        cd /mnt/ssd/docker-projects/caddy
        docker compose up -d || print_warning "Failed to start Caddy"
    fi
    
    # Start GoatCounter
    if [ -f /mnt/ssd/docker-projects/goatcounter/docker-compose.yml ]; then
        print_info "Starting GoatCounter..."
        cd /mnt/ssd/docker-projects/goatcounter
        docker compose up -d || print_warning "Failed to start GoatCounter"
    fi
    
    # Start Nextcloud
    if [ -f /mnt/ssd/apps/nextcloud/docker-compose.yml ]; then
        print_info "Starting Nextcloud..."
        cd /mnt/ssd/apps/nextcloud
        docker compose up -d || print_warning "Failed to start Nextcloud"
    fi
    
    # Start Uptime Kuma
    if [ -f /mnt/ssd/docker-projects/uptime-kuma/docker-compose.yml ]; then
        print_info "Starting Uptime Kuma..."
        cd /mnt/ssd/docker-projects/uptime-kuma
        docker compose up -d || print_warning "Failed to start Uptime Kuma"
    fi
    
    # Start Documents-to-Calendar
    if [ -f /mnt/ssd/docker-projects/documents-to-calendar/docker-compose.yml ]; then
        print_info "Starting Documents-to-Calendar..."
        cd /mnt/ssd/docker-projects/documents-to-calendar
        docker compose build || print_warning "Failed to build Documents-to-Calendar"
        docker compose up -d || print_warning "Failed to start Documents-to-Calendar"
    fi
    
    # Start Pi-hole
    if [ -f /mnt/ssd/docker-projects/pihole/docker-compose.yml ]; then
        print_info "Starting Pi-hole..."
        cd /mnt/ssd/docker-projects/pihole
        docker compose up -d || print_warning "Failed to start Pi-hole"
    fi
    
    print_success "Docker services started"
}

# Function to start systemd services
start_systemd_services() {
    print_info "Starting systemd services..."
    
    if systemctl is-enabled gokapi.service &>/dev/null; then
        sudo systemctl start gokapi.service
        print_success "Gokapi service started"
    fi
    
    if systemctl is-enabled cloudflared.service &>/dev/null; then
        sudo systemctl start cloudflared.service
        print_success "Cloudflared service started"
    fi
}

# Function to verify restore
verify_restore() {
    print_info "Verifying restore..."
    
    echo ""
    echo "=== Docker Services Status ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    echo "=== Systemd Services Status ==="
    systemctl is-active gokapi.service &>/dev/null && echo "✓ Gokapi: $(systemctl is-active gokapi.service)" || echo "✗ Gokapi: not active"
    systemctl is-active cloudflared.service &>/dev/null && echo "✓ Cloudflared: $(systemctl is-active cloudflared.service)" || echo "✗ Cloudflared: not active"
    
    echo ""
    print_success "Restore verification completed"
}

# Main execution
main() {
    echo "=========================================="
    echo "Pi to ThinkCentre Migration Restore"
    echo "=========================================="
    echo ""
    
    # Detect backup directory
    detect_backup_dir
    
    # Check prerequisites
    check_prerequisites
    
    # Install dependencies
    install_dependencies
    
    # Setup SSD mount
    setup_ssd_mount
    
    # Restore network config (with user confirmation)
    restore_network_config
    
    # Create directory structure
    create_directory_structure
    
    # Restore configurations
    restore_docker_configs
    restore_docker_volumes
    restore_application_data
    restore_credentials
    restore_config_repo
    
    # Setup services
    setup_gokapi
    setup_cloudflared
    
    # Start services
    start_docker_services
    start_systemd_services
    
    # Verify restore
    verify_restore
    
    # Summary
    echo ""
    echo "=========================================="
    print_success "Restore completed!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Review network configuration if needed"
    echo "2. Update passwords in docker-compose.yml files"
    echo "3. Verify all services are running: docker ps"
    echo "4. Check service logs if any issues: docker compose logs"
    echo "5. Test access to your services"
    echo ""
    print_warning "You may need to log out and back in for docker group to take effect"
    echo ""
}

# Run main function
main

