#!/bin/bash
###############################################################################
# Add Swap Space
# Creates swap file to prevent freezes from memory pressure
###############################################################################

SWAP_SIZE=${1:-2G}  # Default 2GB, can override: ./add-swap.sh 4G
SWAP_FILE="/swapfile"

echo "Adding ${SWAP_SIZE} swap space..."

# Check if swap already exists
if [ -f "$SWAP_FILE" ] || swapon --show | grep -q "$SWAP_FILE"; then
    echo "Swap file already exists!"
    swapon --show
    read -p "Do you want to remove existing swap and create new? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    echo "Removing existing swap..."
    sudo swapoff "$SWAP_FILE" 2>/dev/null
    sudo rm -f "$SWAP_FILE"
fi

# Check available disk space
AVAILABLE=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
SWAP_SIZE_GB=$(echo "$SWAP_SIZE" | sed 's/G//')

if [ "$SWAP_SIZE_GB" -gt "$AVAILABLE" ]; then
    echo "ERROR: Not enough disk space. Available: ${AVAILABLE}G, Requested: ${SWAP_SIZE_GB}G"
    exit 1
fi

# Create swap file
echo "Creating ${SWAP_SIZE} swap file..."
sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE"

if [ $? -ne 0 ]; then
    echo "fallocate failed, trying dd method..."
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((SWAP_SIZE_GB * 1024)) status=progress
fi

# Set correct permissions
sudo chmod 600 "$SWAP_FILE"

# Format as swap
echo "Formatting swap file..."
sudo mkswap "$SWAP_FILE"

# Enable swap
echo "Enabling swap..."
sudo swapon "$SWAP_FILE"

# Verify
echo ""
echo "Swap status:"
swapon --show
free -h

# Add to fstab if not already there
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "Adding to /etc/fstab for persistence..."
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    echo "✓ Swap will persist across reboots"
else
    echo "✓ Swap already in /etc/fstab"
fi

# Optimize swappiness (reduce swap usage unless necessary)
echo ""
echo "Optimizing swappiness..."
CURRENT_SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "60")
echo "Current swappiness: $CURRENT_SWAPPINESS"

if [ "$CURRENT_SWAPPINESS" -gt 10 ]; then
    echo "Setting swappiness to 10 (lower = use swap less aggressively)"
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    sudo sysctl vm.swappiness=10
    echo "✓ Swappiness optimized"
fi

echo ""
echo "=========================================="
echo "Swap configuration complete!"
echo "=========================================="
echo ""
echo "Swap file: $SWAP_FILE"
echo "Size: $SWAP_SIZE"
echo ""
echo "Current memory and swap:"
free -h












