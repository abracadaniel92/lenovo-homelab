#!/bin/bash
# Script to help identify TV device on network

echo "=== Network Device Discovery ==="
echo ""
echo "Current ARP table entries (192.168.1.x):"
echo "----------------------------------------"
ip neigh show | grep "192.168.1." | grep -v "FAILED\|INCOMPLETE" | while read line; do
    IP=$(echo $line | awk '{print $1}')
    MAC=$(echo $line | awk '{print $5}')
    STATUS=$(echo $line | awk '{print $NF}')
    
    # Try to get hostname
    HOSTNAME=$(getent hosts $IP 2>/dev/null | awk '{print $2}' | head -1)
    
    if [ -z "$HOSTNAME" ]; then
        HOSTNAME="(no hostname)"
    fi
    
    printf "IP: %-15s MAC: %-17s Status: %-10s Hostname: %s\n" "$IP" "$MAC" "$STATUS" "$HOSTNAME"
done

echo ""
echo "=== Instructions ==="
echo "1. Turn on your TV and use it (open an app, browse)"
echo "2. Check Pi-hole Query Log: http://192.168.1.98/admin → Query Log"
echo "3. Look for the IP that appears when TV is active"
echo ""
echo "=== Alternative: Install network scanner ==="
echo "To scan network and identify devices:"
echo "  sudo apt install nmap -y"
echo "  sudo nmap -sn 192.168.1.0/24"
echo ""
echo "=== Check Pi-hole DHCP leases ==="
echo "If Pi-hole handles DHCP, check:"
echo "  http://192.168.1.98/admin → Local DNS → DHCP leases"
echo ""
echo "=== Check TV directly ==="
echo "On your TV: Settings → Network → Network Status"
echo "This will show the TV's IP and MAC address"


