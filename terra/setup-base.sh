#!/bin/bash
# Terra stage 1 (README Part A steps 1, 3 key pair, 5): everything that needs
# nothing from lemongrab. Safe to re-run. Run on the Terra from the repo root:
#   sudo bash terra/setup-base.sh
# Prints the Terra's WireGuard public key at the end; give that to lemongrab.
set -euo pipefail
cd "$(dirname "$0")"

apt-get update
apt-get -y full-upgrade
apt-get install -y openssh-server wireguard-tools nftables unattended-upgrades \
    smartmontools tmux

# Key-only SSH from the moment sshd exists (it's firewalled to wg0 below anyway).
install -m 0644 ../ssh/10-key-only.conf /etc/ssh/sshd_config.d/10-key-only.conf
sshd -t && systemctl reload ssh

# Firewall: no inbound from the work LAN.
install -m 0644 nftables.conf /etc/nftables.conf
nft -c -f /etc/nftables.conf
systemctl enable --now nftables
systemctl restart nftables

# GNOME suspends after 15 min idle; a suspended box is unreachable.
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

echo 'unattended-upgrades unattended-upgrades/enable_auto_updates boolean true' \
    | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

# WireGuard key pair. The private key never leaves this box.
mkdir -p -m 0700 /etc/wireguard
[ -f /etc/wireguard/terra.key ] || (umask 077; wg genkey > /etc/wireguard/terra.key)
wg pubkey < /etc/wireguard/terra.key > /etc/wireguard/terra.pub

echo
echo "Done. Terra WireGuard public key (safe to share):"
cat /etc/wireguard/terra.pub
