# Quick Tool Reference

One-page cheat sheet for installed tools.

## 📊 System Information

```bash
inxi -Fxz          # Full system info (CPU, RAM, disk, network)
glances            # Real-time system monitor (press 'q' to quit)
htop               # Process monitor (already installed)
```

## 🔍 Search & Find

```bash
rg "pattern" /path              # Fast text search (ripgrep)
tree -L 2 /mnt/ssd              # Directory tree visualization
find /mnt/ssd -name "*.log"     # Find files
```

## 📝 JSON Processing

```bash
jq '.' file.json                # Pretty print JSON
curl ... | jq                   # Parse API responses
docker inspect caddy | jq       # Docker JSON
```

## 💾 Disk Usage

```bash
ncdu /                          # Interactive disk usage (navigate with arrows)
ncdu /mnt/ssd                   # Check SSD usage
df -h                           # Quick disk usage
```

## 🐳 Docker Management

```bash
glances                          # Shows Docker stats automatically
docker stats --no-stream         # Container resource usage
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 🔧 Common Tasks

### Check System Status
```bash
inxi -Fxz                       # System overview
glances                          # Real-time monitoring
systemctl status cloudflared.service gokapi.service
```

### Find Configuration
```bash
rg "reverse_proxy" /mnt/ssd/docker-projects
tree -L 2 /mnt/ssd/docker-projects
find /mnt/ssd -name "docker-compose.yml"
```

### Analyze Logs
```bash
rg "error\|warn" /var/log/service-health-check.log | tail -20
journalctl -u cloudflared.service | rg -i "error"
```

### Check Disk Space
```bash
ncdu /mnt/ssd                   # Interactive
df -h | grep -E "/$|/mnt/ssd"    # Quick check
```

### View JSON Configs
```bash
jq '.' /mnt/ssd/apps/gokapi/config/config.json
docker inspect caddy | jq '.[0].Config'
```

## 🎯 Most Useful Commands

```bash
# Morning check
glances                          # System status
docker ps                        # Container status

# Troubleshooting
rg "error\|fail" /var/log/service-health-check.log
journalctl -u cloudflared.service --since "10 minutes ago"

# Find things
tree -L 2 /mnt/ssd/docker-projects
rg "port" /mnt/ssd/docker-projects

# Disk cleanup
ncdu /mnt/ssd
```

## 📚 Full Documentation

- `USEFUL_TOOLS.md` - Detailed tool descriptions
- `TOOL_USAGE_EXAMPLES.md` - Practical examples
- `QUICK_SSH_COMMANDS.md` - Service management commands

