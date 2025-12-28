# Practical Tool Usage Examples

Real-world examples for managing your server.

## 🔍 Finding Things

### Find Configuration Files
```bash
# Find all Caddyfiles
rg "reverse_proxy" /mnt/ssd --type caddyfile

# Find all docker-compose files
find /mnt/ssd -name "docker-compose.yml" -exec tree -L 1 {} \;

# Search for port numbers in configs
rg "\d{4}" /home/goce/Desktop/Cursor\ projects/Pi-version-control --type yaml
```

### Find Large Files
```bash
# Interactive disk usage
ncdu /mnt/ssd

# Find largest Docker images
docker images --format "{{.Repository}}:{{.Tag}}" | xargs -I {} docker image inspect {} --format '{{.Size}} {}' | sort -h
```

## 📊 Monitoring

### Quick System Check
```bash
# System overview
neofetch

# Detailed monitoring
glances

# Process tree
htop
```

### Docker Monitoring
```bash
# Container stats
docker stats --no-stream

# With glances (shows Docker stats automatically)
glances
```

## 🔧 Configuration Management

### View JSON Configs
```bash
# Pretty print Gokapi config
jq '.' /mnt/ssd/apps/gokapi/config/config.json

# Extract specific values
jq '.ServerUrl' /mnt/ssd/apps/gokapi/config/config.json

# View Docker inspect output
docker inspect caddy | jq '.[0].Config'
```

### Directory Structure
```bash
# View Docker projects structure
tree -L 2 /mnt/ssd/docker-projects

# View version control structure
tree -L 2 "/home/goce/Desktop/Cursor projects/Pi-version-control"
```

## 🐳 Docker Management

### Find Container Logs
```bash
# Search for errors in all containers
for container in $(docker ps --format "{{.Names}}"); do
    echo "=== $container ==="
    docker logs "$container" 2>&1 | rg -i "error|warn" | head -5
done
```

### Analyze Docker Usage
```bash
# Disk usage by container
docker system df -v | jq

# Or use glances
glances
# Press 'd' for Docker view
```

## 📝 Log Analysis

### Search Health Check Logs
```bash
# Find all service restarts
rg "Restarting" /var/log/service-health-check.log

# Find errors
rg -i "error|warn|fail" /var/log/service-health-check.log | tail -20

# Count restarts per service
rg "Restarting" /var/log/service-health-check.log | rg -o "Container \w+|Service \w+" | sort | uniq -c
```

### Search Systemd Logs
```bash
# Find errors in cloudflared
journalctl -u cloudflared.service | rg -i "error|fail"

# Find recent bookmarks activity
journalctl -u bookmarks.service --since "1 hour ago" | rg "POST\|GET"
```

## 🔐 Security Checks

### Check Auto-Updates
```bash
# View unattended-upgrades config
cat /etc/apt/apt.conf.d/50unattended-upgrades | jq -R . 2>/dev/null || cat /etc/apt/apt.conf.d/50unattended-upgrades

# Check update logs
cat /var/log/unattended-upgrades/unattended-upgrades.log | tail -20
```

### Check Fail2ban
```bash
# View banned IPs
sudo fail2ban-client status sshd | jq 2>/dev/null || sudo fail2ban-client status sshd
```

## 💾 Backup & Maintenance

### Find What's Using Space
```bash
# Interactive analysis
ncdu /mnt/ssd

# Find large files
find /mnt/ssd -type f -size +100M -exec ls -lh {} \; | awk '{print $5, $9}'
```

### Docker Cleanup
```bash
# See what can be cleaned
docker system df

# View unused images
docker images --filter "dangling=true"
```

## 🌐 Network Debugging

### Check Service Ports
```bash
# Find what's listening
ss -tlnp | rg -o ":\d{4}" | sort -u

# Check if services are accessible
for port in 3000 5000 8080 8081 8091; do
    echo -n "Port $port: "
    timeout 1 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null && echo "✓" || echo "✗"
done
```

## 📋 Quick Status Check

### All-in-One Status
```bash
#!/bin/bash
echo "=== System Info ==="
neofetch --stdout | head -5

echo ""
echo "=== Services ==="
systemctl is-active cloudflared.service gokapi.service bookmarks.service planning-poker.service

echo ""
echo "=== Docker ==="
docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "=== Disk Usage ==="
df -h | grep -E "/$|/mnt/ssd"

echo ""
echo "=== Memory ==="
free -h | grep Mem
```

## 🎯 Daily Use Cases

### Morning Check
```bash
# Quick system status
glances --disable-plugin network,diskio  # Faster startup

# Check if all services are up
systemctl is-active cloudflared.service gokapi.service bookmarks.service planning-poker.service && docker ps -q | wc -l
```

### Troubleshooting
```bash
# Find recent errors
rg -i "error|fail|down" /var/log/service-health-check.log | tail -10

# Check service logs
journalctl -u cloudflared.service --since "10 minutes ago" | rg -i "error"
```

### Before Making Changes
```bash
# View current config
tree -L 2 /mnt/ssd/docker-projects

# Backup important configs
tar -czf backup-$(date +%Y%m%d).tar.gz /mnt/ssd/apps/*/config /home/goce/.cloudflared
```

## 💡 Pro Tips

### Combine Tools
```bash
# Find and view JSON configs
find /mnt/ssd -name "*.json" -exec sh -c 'echo "=== {} ===" && jq . {}' \;

# Search and show context
rg "reverse_proxy" /mnt/ssd/docker-projects --context 3

# Monitor and log
glances --export json --export-file /tmp/glances.json &
sleep 30
jq '.cpu.total' /tmp/glances.json
```

### Create Aliases
Add to `~/.bashrc`:
```bash
# Quick status
alias status='systemctl is-active cloudflared.service gokapi.service bookmarks.service planning-poker.service && docker ps --format "{{.Names}}: {{.Status}}"'

# Quick logs
alias logs='journalctl -u cloudflared.service -n 50 --no-pager'

# Quick structure
alias struct='tree -L 2 /mnt/ssd/docker-projects'
```

## 🔗 Integration with Existing Scripts

### Enhance Health Check
```bash
# Add to health-check-and-restart.sh
if command -v glances &> /dev/null; then
    glances --disable-plugin network,diskio --time 1 --export json | jq '.cpu.total' >> /tmp/cpu_usage.log
fi
```

### Monitor Disk Space
```bash
# Add to health check
if command -v ncdu &> /dev/null; then
    ncdu -o /tmp/disk_usage.json /mnt/ssd
    jq '.[0].asize' /tmp/disk_usage.json
fi
```

