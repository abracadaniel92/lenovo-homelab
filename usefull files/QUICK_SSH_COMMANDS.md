# Quick SSH Commands Reference

Quick reference for troubleshooting services from your phone via SSH.

## 📜 Available Scripts

All scripts are located in: `/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/`

- **fix-all-services.sh** - Comprehensive service recovery (recommended)
- **emergency-fix.sh** - Quick emergency recovery
- **fix-subdomains-down.sh** - Fix subdomain routing issues
- **permanent-auto-recovery.sh** - Set up permanent auto-recovery (run once)
- **health-check-and-restart.sh** - Health check script
- **fix-health-check-service.sh** - Fix health check service

## 🚨 EMERGENCY FIX (Everything Down)

**If everything is down, run this first (COMPREHENSIVE FIX):**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-all-services.sh"
```

This will:
- ✅ Fix UDP buffer sizes (Cloudflare tunnel stability)
- ✅ Start Docker if stopped
- ✅ Start Caddy first (critical - reverse proxy)
- ✅ Start all Docker containers
- ✅ Start all systemd services
- ✅ Test local connectivity
- ✅ Show status

**Or use the simpler emergency fix:**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/emergency-fix.sh"
```

## 🌐 FIX SUBDOMAINS DOWN (502/404 Errors)

**If all subdomains are returning 502/404 but services are running locally:**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-subdomains-down.sh"
```

This will:
- ✅ Restart Caddy (reverse proxy)
- ✅ Restart Cloudflare Tunnel (requires sudo password)
- ✅ Test local connectivity
- ✅ Test external access
- ✅ Show status and logs

**Quick manual fix:**
```bash
sudo systemctl restart cloudflared.service
docker restart caddy
```

## 🚀 QUICK FIX ALL (Services Running But Issues)

**Comprehensive fix for all services:**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-all-services.sh"
```

This script will:
- ✅ Fix UDP buffer sizes (Cloudflare tunnel stability)
- ✅ Check and start Docker
- ✅ Start Caddy first (critical - reverse proxy)
- ✅ Start all Docker containers
- ✅ Start all systemd services
- ✅ Test local connectivity
- ✅ Show status

**Perfect for fixing issues from your phone!** 📱

## 🛡️ PERMANENT PREVENTION (Run Once)

**To prevent downtime from happening again:**
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/permanent-auto-recovery.sh"
```

This sets up:
- ✅ Health check every 30 seconds
- ✅ Continuous watchdog (every 20 seconds)
- ✅ Auto-restart on failures
- ✅ Boot protection

**Run this ONCE and services will auto-recover!**

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
# Comprehensive service recovery (recommended)
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-all-services.sh"
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

### All Subdomains Down (502/404 Error)
```bash
# Use the fix script (recommended)
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-subdomains-down.sh"

# Or manually:
sudo systemctl restart cloudflared.service
docker restart caddy
sleep 5

# Check status
systemctl status cloudflared.service
docker ps | grep caddy

# Check logs
journalctl -u cloudflared.service -n 30 --no-pager
docker logs caddy --tail 30
```

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
# Restart everything (comprehensive fix)
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-all-services.sh"

# Or manually:
sudo systemctl restart cloudflared.service
docker restart caddy
sudo systemctl restart bookmarks.service
sudo systemctl restart planning-poker.service
sudo systemctl restart gokapi.service
```

### Nextcloud 502 Bad Gateway
```bash
# Check if Nextcloud is running
docker ps | grep nextcloud

# Test direct access
curl http://localhost:8081

# Check Caddy routing
curl -I http://localhost:8080 -H "Host: cloud.gmojsoski.com"

# If 502, verify Caddyfile uses host IP (not container hostname)
docker exec caddy cat /etc/caddy/Caddyfile | grep -A5 "@cloud"

# Reload Caddy if needed
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

### Poker Frontend Not Loading (CSS/JS 404)
```bash
# Test if static files load directly
curl http://localhost:3000/style.css
curl http://localhost:3000/app.js

# Test via Caddy
curl -I http://localhost:8080/style.css -H "Host: poker.gmojsoski.com"

# Check Caddy route has Host header forwarding
docker exec caddy cat /etc/caddy/Caddyfile | grep -A5 "@poker"

# Reload Caddy if needed
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
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
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/fix-all-services.sh"

# 9. Fix Nextcloud 502 (if Caddy can't reach container)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile

# 10. Fix Poker frontend (reload Caddy after config change)
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

## 💾 Backups

### Backup All Critical Services (Recommended)
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-all-critical.sh"
```

This backs up: Vaultwarden, Nextcloud, TravelSync, and KitchenOwl

### Individual Service Backups

**Vaultwarden (CRITICAL - Passwords):**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-vaultwarden.sh"
```

**Nextcloud (User Files & Database):**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-nextcloud.sh"
```

**TravelSync (Travel Data):**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-travelsync.sh"
```

**KitchenOwl (Shopping Lists):**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/backup-kitchenowl.sh"
```

### Restore from Backup

**KitchenOwl:**
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/restore-kitchenowl.sh"
```

### Setup Automated Daily Backups (One-time)
```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/setup-all-backups-cron.sh"
```

**Backup locations:**
- Vaultwarden: `/mnt/ssd/backups/vaultwarden/`
- Nextcloud: `/mnt/ssd/backups/nextcloud/`
- TravelSync: `/mnt/ssd/backups/travelsync/`
- KitchenOwl: `/mnt/ssd/backups/kitchenowl/`

**Schedule:** Daily at 2:00 AM (after setup)  
**Backups kept:** Last 30 automatically for each service

## 📝 Notes

- All `sudo` commands require your password
- Most services auto-restart on failure, but manual restart is faster
- Health check runs every 2 minutes and will auto-restart services
- Check logs if service won't start after restart
- **Always backup KitchenOwl before making container changes!**

## 🔧 Common Issues & Quick Fixes

### Nextcloud 502 Error
**Cause**: Caddy and Nextcloud on different Docker networks  
**Quick Fix**: Caddyfile should use `http://172.17.0.1:8081` not `http://nextcloud-app:80`  
**Verify**: `docker exec caddy cat /etc/caddy/Caddyfile | grep -A5 "@cloud"`

### Poker CSS/JS Not Loading
**Cause**: Missing Host header forwarding in Caddy  
**Quick Fix**: Ensure Caddy route has `header_up Host {host}`  
**Verify**: `docker exec caddy cat /etc/caddy/Caddyfile | grep -A5 "@poker"`

### Service Running But Not Accessible Publicly
**Cause**: Cloudflare tunnel not forwarding  
**Quick Fix**: `sudo systemctl restart cloudflared.service`

## 🔗 Related Files

- Main fix script: `scripts/fix-all-services.sh`
- Auto-recovery: `scripts/permanent-auto-recovery.sh`
- Archived scripts: `scripts/archive/README.md`

