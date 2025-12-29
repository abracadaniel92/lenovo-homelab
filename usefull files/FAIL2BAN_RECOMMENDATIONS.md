# Fail2ban Recommended Settings

## Current Configuration

After installation, fail2ban has basic protection. Here are recommended optimizations:

## 1. Whitelist Local Network

**Why**: Prevent banning your own IP or devices on your local network.

**How**: Run the optimization script:
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/optimize-fail2ban.sh"
```

Or manually edit `/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24
```

Replace `192.168.1.0/24` with your local network range.

## 2. Progressive Ban Times

**Why**: Repeat offenders get longer bans automatically.

**Settings**:
```ini
[DEFAULT]
bantime = 3600              # First ban: 1 hour
bantime.increment = true    # Enable progressive bans
bantime.maxtime = 86400    # Maximum ban: 24 hours
bantime.factor = 2          # Double ban time each offense
```

**Result**: 1h → 2h → 4h → 8h → 24h (max)

## 3. Use Systemd Backend

**Why**: Better performance and integration with systemd services.

**Setting**:
```ini
[DEFAULT]
backend = systemd
```

## 4. Email Notifications (Optional)

**Why**: Get notified when IPs are banned.

**Setup**:
1. Install mail utility:
   ```bash
   sudo apt install mailutils
   ```

2. Edit `/etc/fail2ban/jail.local`:
   ```ini
   [DEFAULT]
   destemail = your-email@example.com
   sendername = Fail2Ban
   action = %(action_mwl)s
   ```

3. Restart fail2ban:
   ```bash
   sudo systemctl restart fail2ban
   ```

## 5. Additional Jails (Optional)

### Protect Web Services

If you want to protect web services from brute force:

**Nextcloud** (if using Apache):
```ini
[nextcloud]
enabled = true
port = http,https
logpath = /var/log/nextcloud/access.log
maxretry = 5
bantime = 3600
```

**Caddy** (if logging enabled):
```ini
[caddy]
enabled = true
port = http,https
logpath = /var/log/caddy/access.log
maxretry = 10
bantime = 3600
```

**Note**: Most services are behind Cloudflare, so this may not be necessary.

## 6. Stricter SSH Settings

For high-security environments:

```ini
[sshd]
enabled = true
port = ssh,222,223
maxretry = 3        # Ban after 3 attempts (instead of 5)
findtime = 300      # 5 minute window (instead of 10)
bantime = 7200      # 2 hour ban (instead of 1)
```

## Quick Optimization

Run the optimization script to apply all recommended settings:

```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/optimize-fail2ban.sh"
```

This will:
- ✅ Whitelist your local network
- ✅ Enable progressive ban times
- ✅ Use systemd backend
- ✅ Keep existing SSH protection

## Verify Settings

After optimization:

```bash
# Check overall status
sudo fail2ban-client status

# Check SSH jail details
sudo fail2ban-client status sshd

# View configuration
sudo cat /etc/fail2ban/jail.local
```

## Monitoring

### View Recent Bans
```bash
sudo fail2ban-client status sshd | grep "Banned IP"
```

### View Fail2ban Logs
```bash
sudo tail -f /var/log/fail2ban.log
```

### View SSH Attempts
```bash
sudo tail -f /var/log/auth.log | grep sshd
```

## Recommended Settings Summary

| Setting | Recommended Value | Why |
|---------|-------------------|-----|
| **bantime** | 3600 (1 hour) | Reasonable first ban |
| **bantime.increment** | true | Progressive bans for repeat offenders |
| **bantime.maxtime** | 86400 (24h) | Maximum ban time |
| **maxretry** | 5 | Balance between security and false positives |
| **findtime** | 600 (10 min) | Reasonable time window |
| **ignoreip** | Local network | Prevent self-banning |
| **backend** | systemd | Better performance |

## Important Notes

1. **Don't lock yourself out**: Always whitelist your local network
2. **Cloudflare IPs**: If accessing through Cloudflare, you'll see Cloudflare IPs in logs
3. **Test carefully**: Make sure you can still access SSH after changes
4. **Backup config**: The optimization script creates a backup automatically

## Troubleshooting

### Can't SSH after changes
```bash
# Unban your IP
sudo fail2ban-client set sshd unbanip <YOUR_IP>

# Or unban all
sudo fail2ban-client set sshd unban --all
```

### Too many false positives
- Increase `maxretry` value
- Increase `findtime` value
- Add more IPs to `ignoreip`

### Check if fail2ban is working
```bash
# Check service
sudo systemctl status fail2ban

# Check logs
sudo tail -50 /var/log/fail2ban.log

# Test configuration
sudo fail2ban-client -d
```

