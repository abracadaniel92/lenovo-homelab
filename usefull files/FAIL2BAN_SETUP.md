# Fail2ban Setup Guide

## What is Fail2ban?

Fail2ban is an intrusion prevention system that monitors log files and bans IPs that show malicious behavior (like too many failed login attempts). It's especially useful for protecting SSH and web services from brute force attacks.

## Why Install It?

Even though you're using Cloudflare Tunnel (which provides DDoS protection), fail2ban adds an extra layer of security:

1. **SSH Protection**: Prevents brute force attacks on SSH
2. **Local Service Protection**: Protects services accessible on your local network
3. **Low Overhead**: Minimal resource usage
4. **Easy to Configure**: Simple setup and management

## Current Security Status

- ✅ **Cloudflare Tunnel**: Provides DDoS protection and WAF for public-facing services
- ✅ **Services behind tunnel**: Protected by Cloudflare
- ⚠️ **SSH**: Directly exposed (if port 22 is open)
- ⚠️ **Local services**: Accessible on local network

## Installation

### Quick Install
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/setup-fail2ban.sh"
```

### Manual Install
```bash
sudo apt update
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

## Configuration

The setup script creates `/etc/fail2ban/jail.local` with:

- **SSH Protection**: Enabled by default
  - 5 failed attempts = 1 hour ban
  - Monitors SSH login attempts

- **Nextcloud Protection**: Disabled by default (can be enabled if needed)
- **Caddy Protection**: Disabled by default (can be enabled if needed)

## Default Settings

- **Ban Time**: 3600 seconds (1 hour)
- **Time Window**: 600 seconds (10 minutes)
- **Max Retries**: 5 failed attempts

## Useful Commands

### Check Status
```bash
# Overall status
sudo fail2ban-client status

# SSH jail status
sudo fail2ban-client status sshd

# View banned IPs
sudo fail2ban-client status sshd | grep "Banned IP"
```

### Manage Bans
```bash
# Unban an IP
sudo fail2ban-client set sshd unbanip <IP_ADDRESS>

# Ban an IP manually
sudo fail2ban-client set sshd banip <IP_ADDRESS>

# Unban all IPs
sudo fail2ban-client set sshd unban --all
```

### View Logs
```bash
# Fail2ban logs
sudo tail -f /var/log/fail2ban.log

# SSH logs (to see what fail2ban is monitoring)
sudo tail -f /var/log/auth.log
```

## Customization

Edit `/etc/fail2ban/jail.local` to customize:

```ini
[DEFAULT]
bantime = 3600      # Ban duration in seconds
findtime = 600      # Time window to count failures
maxretry = 5        # Number of failures before ban

[sshd]
enabled = true
maxretry = 5        # SSH-specific retry count
bantime = 3600      # SSH-specific ban time
```

## Important Notes

1. **Don't lock yourself out**: Make sure you have access to unban your own IP if needed
2. **Cloudflare IPs**: If you access SSH through Cloudflare, you might see Cloudflare IPs in logs
3. **Local Network**: Consider whitelisting your local network IP range
4. **Email Notifications**: Can be configured to send email alerts (see jail.local)

## Whitelist Local Network (Optional)

To prevent banning your local network, add to `/etc/fail2ban/jail.local`:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24
```

Replace `192.168.1.0/24` with your local network range.

## Testing

After installation, you can test (carefully):

```bash
# Check if fail2ban is monitoring
sudo fail2ban-client status sshd

# View recent SSH attempts
sudo tail -20 /var/log/auth.log | grep sshd
```

## Troubleshooting

### Fail2ban not working
```bash
# Check service status
sudo systemctl status fail2ban

# Check logs
sudo tail -50 /var/log/fail2ban.log

# Restart service
sudo systemctl restart fail2ban
```

### Too many false positives
- Increase `maxretry` value
- Increase `findtime` value
- Add trusted IPs to `ignoreip`

## Recommendation

**Yes, install fail2ban** - It's a low-overhead security measure that provides good protection for SSH and can be extended to protect other services. The setup script makes it easy to install and configure.

