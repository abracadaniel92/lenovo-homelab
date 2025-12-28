# Quick SSH Commands Reference

Quick reference for troubleshooting services from your phone via SSH.

## 🔄 Restart Services

### Restart Individual Services
```bash
# Restart Cloudflare Tunnel
sudo systemctl restart cloudflared.service

# Restart Caddy (Docker)
docker restart caddy

# Restart Bookmarks
sudo systemctl restart bookmarks.service

# Restart Planning Poker
sudo systemctl restart planning-poker.service

# Restart Gokapi
sudo systemctl restart gokapi.service
```

### Restart All Services
```bash
# Quick restart script
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"
```

### Restart Docker Containers
```bash
# Restart specific container
docker restart caddy
docker restart goatcounter
docker restart nextcloud-app
docker restart uptime-kuma
docker restart pihole
docker restart documents-to-calendar

# Restart all containers
docker restart $(docker ps -q)
```

## 📊 Check Service Status

### Check Systemd Services
```bash
# Check all systemd services
systemctl status cloudflared.service
systemctl status gokapi.service
systemctl status bookmarks.service
systemctl status planning-poker.service

# Check all at once
systemctl status cloudflared.service gokapi.service bookmarks.service planning-poker.service

# Check if service is running (quick)
systemctl is-active cloudflared.service && echo "✓ Running" || echo "✗ Not running"
```

### Check Docker Containers
```bash
# List all containers
docker ps

# Check specific container
docker ps | grep caddy
docker ps | grep nextcloud

# Check container logs
docker logs caddy --tail 50
docker logs nextcloud-app --tail 50
```

### Check Ports
```bash
# Check if ports are listening
ss -tlnp | grep 8080  # Caddy
ss -tlnp | grep 5000  # Bookmarks
ss -tlnp | grep 3000  # Poker
ss -tlnp | grep 8091  # Gokapi
```

## 🌐 Test Endpoints

### Test Local Services
```bash
# Test Caddy
curl -I http://localhost:8080

# Test Bookmarks
curl http://localhost:5000/

# Test Poker
curl http://localhost:3000

# Test Gokapi
curl http://localhost:8091
```

### Test Public Endpoints
```bash
# Test main site
curl -I https://gmojsoski.com

# Test other services
curl -I https://bookmarks.gmojsoski.com
curl -I https://poker.gmojsoski.com
curl -I https://analytics.gmojsoski.com
curl -I https://files.gmojsoski.com
curl -I https://cloud.gmojsoski.com
```

## 🔍 View Logs

### Systemd Service Logs
```bash
# Cloudflared logs
journalctl -u cloudflared.service -n 50 --no-pager

# Bookmarks logs
journalctl -u bookmarks.service -n 50 --no-pager

# Poker logs
journalctl -u planning-poker.service -n 50 --no-pager

# Follow logs in real-time
journalctl -u cloudflared.service -f
```

### Docker Logs
```bash
# Caddy logs
docker logs caddy --tail 50

# All containers logs
docker logs caddy --tail 20
docker logs nextcloud-app --tail 20
docker logs goatcounter --tail 20
```

### Health Check Logs
```bash
# View health check log
tail -50 /var/log/service-health-check.log

# Follow health check log
tail -f /var/log/service-health-check.log
```

## 🚨 Common Issues & Quick Fixes

### Cloudflare Tunnel Down (502 Error)
```bash
# Restart tunnel
sudo systemctl restart cloudflared.service

# Check status
systemctl status cloudflared.service

# Check logs
journalctl -u cloudflared.service -n 30 --no-pager
```

### Caddy Down
```bash
# Restart Caddy
docker restart caddy

# Check status
docker ps | grep caddy

# Check logs
docker logs caddy --tail 30
```

### All Services Down
```bash
# Restart everything
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"

# Or manually:
sudo systemctl restart cloudflared.service
docker restart caddy
sudo systemctl restart bookmarks.service
sudo systemctl restart planning-poker.service
sudo systemctl restart gokapi.service
```

### Service Won't Start
```bash
# Check why service failed
systemctl status <service-name> -l

# View recent errors
journalctl -u <service-name> -n 50 --no-pager | grep -i error
```

## 🔧 System Checks

### Check System Resources
```bash
# Memory usage
free -h

# Disk usage
df -h

# CPU usage
top -bn1 | head -20
```

### Check Docker
```bash
# Docker status
systemctl status docker

# Restart Docker if needed
sudo systemctl restart docker
```

### Check Network
```bash
# Network interfaces
ip addr show

# Test connectivity
ping -c 3 8.8.8.8
```

## 📱 One-Liner Quick Fixes

### Quick Restart Everything
```bash
sudo systemctl restart cloudflared.service && docker restart caddy && sudo systemctl restart bookmarks.service planning-poker.service gokapi.service && echo "All services restarted"
```

### Quick Status Check
```bash
echo "=== Systemd Services ===" && systemctl is-active cloudflared.service gokapi.service bookmarks.service planning-poker.service && echo "" && echo "=== Docker Containers ===" && docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Quick Test All Endpoints
```bash
for url in gmojsoski.com bookmarks.gmojsoski.com poker.gmojsoski.com analytics.gmojsoski.com files.gmojsoski.com; do echo -n "$url: "; curl -s -o /dev/null -w "%{http_code}" https://$url && echo "" || echo "FAILED"; done
```

## 🎯 Most Common Commands (Copy-Paste Ready)

```bash
# 1. Restart Cloudflare Tunnel
sudo systemctl restart cloudflared.service

# 2. Restart Caddy
docker restart caddy

# 3. Restart Bookmarks
sudo systemctl restart bookmarks.service

# 4. Restart Poker
sudo systemctl restart planning-poker.service

# 5. Check all services status
systemctl status cloudflared.service gokapi.service bookmarks.service planning-poker.service && docker ps

# 6. View Cloudflare logs
journalctl -u cloudflared.service -n 30 --no-pager

# 7. View health check log
tail -30 /var/log/service-health-check.log

# 8. Restart everything
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/ensure-services-running.sh"
```

## 📝 Notes

- All `sudo` commands require your password
- Most services auto-restart on failure, but manual restart is faster
- Health check runs every 2 minutes and will auto-restart services
- Check logs if service won't start after restart

## 🔗 Related Files

- Health check script: `scripts/health-check-and-restart.sh`
- Service startup script: `scripts/ensure-services-running.sh`
- Service status: `SERVICES_STATUS.md`
- Troubleshooting: `STABILITY_FIXES.md`

