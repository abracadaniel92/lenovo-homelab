# Reliability Improvements - Preventing Downtime

## Problem Summary

From this conversation, we've experienced multiple downtimes caused by:
1. **Cloudflare tunnel crashes** - Single point of failure
2. **Health check gaps** - Monitoring stopped for hours
3. **No notifications** - Kuma not configured to alert
4. **Slow recovery** - Multiple restart attempts needed

## Proposed Solutions

### Solution 1: Multi-Replica Cloudflare Tunnel (RECOMMENDED)

**What**: Run 2+ cloudflared instances instead of 1

**Why**: If one crashes, the other keeps serving traffic

**How**: 
```bash
# Stop systemd service
sudo systemctl stop cloudflared.service
sudo systemctl disable cloudflared.service

# Start Docker-based tunnel with replicas
cd /mnt/ssd/docker-projects/cloudflared
docker compose up -d
```

**Benefits**:
- ✅ Zero downtime during crashes
- ✅ Cloudflare handles failover automatically
- ✅ Docker auto-restarts failed containers
- ✅ Better isolation and resource management

**Files**: `docker/cloudflared/docker-compose.yml`

---

### Solution 2: Watchdog for Health Check Timer

**What**: Monitor the health check timer itself

**Why**: The timer stopped for 8+ hours without detection

**How**: Create a secondary watchdog service

```bash
# Create watchdog script
cat > /usr/local/bin/healthcheck-watchdog.sh << 'EOF'
#!/bin/bash
# Ensures health check timer is always running

if ! systemctl is-active --quiet enhanced-health-check.timer; then
    logger "WATCHDOG: Health check timer was stopped, restarting..."
    systemctl start enhanced-health-check.timer
fi
EOF

chmod +x /usr/local/bin/healthcheck-watchdog.sh

# Add to crontab (runs every 5 minutes)
echo "*/5 * * * * root /usr/local/bin/healthcheck-watchdog.sh" | sudo tee -a /etc/crontab
```

---

### Solution 3: Configure Kuma Notifications (CRITICAL)

**What**: Set up alerts in Uptime Kuma

**Why**: You didn't receive any notifications during downtime

**How**:
1. Open http://localhost:3001
2. Settings → Notifications → Add
3. Choose Telegram/Email/Discord
4. Enable for all monitors

**See**: `KUMA_NOTIFICATIONS_SETUP.md`

---

### Solution 4: Multiple Health Check Sources

**What**: Don't rely on just one health check

**Why**: If the health check stops, nothing monitors services

**How**: 
- Local systemd health check (current)
- External Uptime Kuma
- Cloudflare health checks (in dashboard)
- BetterStack (already configured for gmojsoski.com)

---

### Solution 5: Direct Port Forwarding (Backup)

**What**: Open ports 80/443 on router as backup

**Why**: If tunnel fails completely, direct access still works

**How**:
1. Configure router to forward 80→8080 and 443→8443
2. Use Cloudflare DNS proxy (not tunnel)
3. Enable when tunnel is completely broken

**Note**: This exposes your server IP, but provides emergency access

---

## Implementation Priority

### Do Now (5 minutes each)

1. **Configure Kuma notifications** ⭐
   - Open http://localhost:3001
   - Set up Telegram or Email alerts

2. **Add health check watchdog**
   ```bash
   sudo bash -c 'cat > /usr/local/bin/healthcheck-watchdog.sh << "EOF"
#!/bin/bash
if ! systemctl is-active --quiet enhanced-health-check.timer; then
    logger "WATCHDOG: Restarting health check timer"
    systemctl start enhanced-health-check.timer
fi
EOF'
   sudo chmod +x /usr/local/bin/healthcheck-watchdog.sh
   echo "*/5 * * * * root /usr/local/bin/healthcheck-watchdog.sh" | sudo tee -a /etc/crontab
   ```

### Do This Week

3. **Switch to Docker-based tunnel with replicas**
   - More reliable than systemd service
   - Automatic failover

### Consider Later

4. **Set up direct port forwarding as backup**
   - Emergency access method
   - Router configuration needed

---

## Expected Results After Implementation

| Scenario | Before | After |
|----------|--------|-------|
| Tunnel crashes | All services down | One replica down, services continue |
| Health check stops | No monitoring for hours | Watchdog restarts within 5 min |
| Services go down | No notification | Telegram/Email alert immediately |
| Need manual fix | SSH required | Auto-recovery in most cases |

---

## Quick Reference

### Check tunnel status
```bash
# Systemd (current)
systemctl status cloudflared.service

# Docker (after migration)
docker compose -f /mnt/ssd/docker-projects/cloudflared/docker-compose.yml ps
```

### Manual tunnel restart
```bash
# Systemd (current)
sudo systemctl restart cloudflared.service

# Docker (after migration)
cd /mnt/ssd/docker-projects/cloudflared && docker compose restart
```

### Check health check timer
```bash
systemctl status enhanced-health-check.timer
```

### Force health check run
```bash
sudo /usr/local/bin/enhanced-health-check.sh
```

---

## Monitoring Dashboard

After implementing all solutions:

| Check | How | Frequency |
|-------|-----|-----------|
| Tunnel | Docker health check | Every 30s |
| Services | enhanced-health-check.sh | Every 30s |
| Timer | healthcheck-watchdog.sh | Every 5min |
| External | Uptime Kuma | Every 60s |
| External | BetterStack | Every 30s |

---

## Related Files

- `docker/cloudflared/docker-compose.yml` - HA tunnel setup
- `docker/cloudflared/README.md` - Tunnel documentation
- `KUMA_NOTIFICATIONS_SETUP.md` - Alert configuration
- `MONITORING_AND_RECOVERY.md` - Monitoring overview
- `AUTO_DOWNTIME_FIX.md` - Auto-recovery details


