#!/bin/bash

###############################################################################
# XRDP Setup Script
# Installs and configures XRDP for remote desktop access
###############################################################################

echo "Installing XRDP..."
sudo apt update
sudo apt install -y xrdp

echo "Configuring XRDP..."
# Add user to ssl-cert group (needed for XRDP)
sudo usermod -aG ssl-cert goce

# Enable and start XRDP
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Configure XRDP to use GNOME
echo "gnome-session" > ~/.xsession

# Allow XRDP through firewall
sudo ufw allow 3389/tcp

echo "XRDP setup complete!"
echo ""
echo "To connect:"
echo "  Host: your-server-ip or no-ip-hostname"
echo "  Port: 3389"
echo "  Username: goce"
echo "  Password: your user password"
echo ""
echo "Note: You may need to log out and back in for group changes to take effect."























