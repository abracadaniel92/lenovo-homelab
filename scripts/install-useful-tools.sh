#!/bin/bash
###############################################################################
# Install Useful Tools (Safe, Non-Breaking)
# These tools improve productivity and monitoring without affecting services
###############################################################################

echo "=========================================="
echo "Installing Useful Tools"
echo "=========================================="
echo ""

# Update package list
echo "1. Updating package list..."
sudo apt update

echo ""
echo "2. Installing essential utilities..."

# Essential tools (safe, won't break anything)
TOOLS=(
    "jq"              # JSON processor (useful for APIs, webhooks)
    "tree"            # Directory tree visualization
    "ripgrep"         # Fast text search (rg command)
    "glances"         # Advanced system monitoring
    "neofetch"        # System information display
    "unattended-upgrades"  # Automatic security updates (safe)
    "apt-listchanges" # View changelogs before updates
    "ncdu"            # Disk usage analyzer (better than du)
)

for tool in "${TOOLS[@]}"; do
    if dpkg -l | grep -q "^ii.*$tool "; then
        echo "   ✓ $tool already installed"
    else
        echo "   → Installing $tool..."
        sudo apt install -y "$tool" 2>&1 | grep -E "Setting up|already" || echo "     Installed"
    fi
done

echo ""
echo "3. Configuring unattended-upgrades..."
if [ -f /etc/apt/apt.conf.d/50unattended-upgrades ]; then
    echo "   ✓ Unattended upgrades already configured"
    echo "   → To reconfigure: sudo dpkg-reconfigure -plow unattended-upgrades"
else
    echo "   → Configuring automatic security updates..."
    sudo dpkg-reconfigure -plow unattended-upgrades <<EOF
yes
EOF
fi

echo ""
echo "4. Optional: Installing bat (better cat with syntax highlighting)..."
if ! command -v bat &> /dev/null; then
    echo "   → bat not in apt, can install from GitHub if needed"
    echo "   → Download from: https://github.com/sharkdp/bat/releases"
else
    echo "   ✓ bat already installed"
fi

echo ""
echo "5. Optional: Installing lazydocker (Docker UI)..."
if ! command -v lazydocker &> /dev/null; then
    echo "   → lazydocker not in apt, can install from GitHub if needed"
    echo "   → Download from: https://github.com/jesseduffield/lazydocker/releases"
    echo "   → Or use: curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash"
else
    echo "   ✓ lazydocker already installed"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Installed tools:"
echo "  • jq - JSON processor (try: curl ... | jq)"
echo "  • tree - Directory tree (try: tree -L 2)"
echo "  • ripgrep - Fast search (try: rg 'pattern')"
echo "  • glances - System monitor (try: glances)"
echo "  • neofetch - System info (try: neofetch)"
echo "  • ncdu - Disk usage (try: ncdu /)"
echo "  • unattended-upgrades - Auto security updates"
echo ""
echo "Quick test commands:"
echo "  neofetch                    # System info"
echo "  glances                     # System monitor"
echo "  tree -L 2 /mnt/ssd          # Directory tree"
echo "  rg 'pattern' /path          # Fast search"
echo "  jq '.' file.json           # Pretty print JSON"
echo "  ncdu /                     # Disk usage"
echo ""

