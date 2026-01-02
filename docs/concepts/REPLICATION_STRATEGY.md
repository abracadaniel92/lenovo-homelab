# Infrastructure Replication Strategy

## Current Infrastructure Overview

- **Server**: lemongrab (192.168.1.97)
- **Storage**: 512GB NVMe SSD (~374GB Docker data)
- **Services**: 15 Docker containers + 3 systemd services
- **Critical Data**: ~100MB (databases, configs)
- **Media Data**: ~5GB+ (Jellyfin media library)

---

## Replication Options

### Option 1: Data Backups Only (Recommended for Now) ✅

**What**: Backup critical data to cloud/external storage, keep services on one machine.

**Pros**:
- ✅ Low cost (~$1-5/month for cloud storage)
- ✅ Simple setup
- ✅ Fast recovery
- ✅ Already have daily backups (just needs offsite)

**Cons**:
- ❌ Services are down during recovery
- ❌ Takes time to restore

**Best for**: Personal infrastructure, cost-conscious setup

**Implementation**:
```bash
# Option A: Cloud Backup (rsync to cloud storage)
# Option B: Remote backup server
# Option C: External hard drive rotation
```

---

### Option 2: Full Replica (Hot Standby) 🏥

**What**: Complete duplicate of infrastructure on another machine/cloud.

**Pros**:
- ✅ Instant failover (high availability)
- ✅ Zero downtime
- ✅ Testing environment
- ✅ Geographic redundancy

**Cons**:
- ❌ Expensive ($20-100+/month for cloud VPS)
- ❌ Complex setup (sync configuration)
- ❌ Double bandwidth/storage costs
- ❌ Requires load balancer or DNS failover

**Best for**: Production-critical systems, high uptime requirements

---

### Option 3: Hybrid Approach 🎯

**What**: Critical services replicated, media/content on primary only.

**Pros**:
- ✅ Balance of cost and availability
- ✅ Critical services always available
- ✅ Media can be restored from backups

**Cons**:
- ⚠️ Media unavailable during primary outage
- ⚠️ More complex than single backup

---

## Recommendations by Service

### 🔴 CRITICAL - Should be Replicated/Backed Up Offsite

| Service | Data Size | Replication Type | Priority |
|---------|-----------|------------------|----------|
| **Vaultwarden** | ~2MB | Full replica OR offsite backup | **CRITICAL** |
| **Nextcloud** | ~50MB | Offsite backup (sync) | **HIGH** |
| **Configuration** | ~10MB | Git repo + offsite backup | **HIGH** |

### 🟡 IMPORTANT - Backup Recommended

| Service | Data Size | Replication Type | Priority |
|---------|-----------|------------------|----------|
| **TravelSync** | <1MB | Offsite backup | Medium |
| **KitchenOwl** | ~1MB | Offsite backup | Medium |
| **Gokapi** | Variable | Offsite backup | Medium |

### 🟢 NICE TO HAVE - Optional

| Service | Data Size | Replication Type | Priority |
|---------|-----------|------------------|----------|
| **Jellyfin Media** | 5GB+ | Local backup OR cloud (expensive) | Low |
| **GoatCounter** | <1MB | Optional (just analytics) | Low |
| **Uptime Kuma** | ~80MB | Optional (just monitoring data) | Low |

---

## Implementation Options

### Option A: Cloud Storage Backup (Recommended Start)

**Services**: Backblaze B2, AWS S3, DigitalOcean Spaces, rsync.net

**Setup**:
1. Install backup tool (rclone, restic, or rsync)
2. Sync backups to cloud daily
3. Keep last 30-90 days of backups

**Cost**: ~$1-5/month for ~10GB backups

**Example with rclone**:
```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure cloud storage (Backblaze B2 example)
rclone config

# Sync backups daily
rclone sync /mnt/ssd/backups/ remote:lemongrab-backups/ --progress
```

---

### Option B: VPS Replica (Full Duplicate)

**Providers**: Hetzner, DigitalOcean, Linode, Vultr, Contabo

**Recommended Specs**:
- **2-4 CPU cores**
- **4-8GB RAM**
- **100GB+ SSD** (or more for media)
- **Cost**: $5-20/month

**Setup**:
1. Deploy fresh Debian/Ubuntu server
2. Install Docker and dependencies
3. Copy docker-compose files
4. Restore backups
5. Point Cloudflare Tunnel to replica (failover)

**Example Hetzner Setup**:
```bash
# On replica server
# 1. Clone repository
git clone https://github.com/abracadaniel92/lenovo-version-control.git

# 2. Run setup scripts
cd Pi-version-control
bash setup-all-services.sh

# 3. Restore backups
bash restore-from-backups.sh
```

---

### Option C: Local Replica (Second Physical Server)

**Use Case**: Raspberry Pi 4, old laptop, second desktop

**Setup**: Similar to VPS but on local network

**Pros**:
- ✅ No monthly cost (after hardware)
- ✅ Fast local sync
- ✅ Can serve as local backup target

**Cons**:
- ❌ Still vulnerable to local disasters
- ❌ Requires physical space
- ❌ Power consumption

---

## Recommended Implementation Plan

### Phase 1: Offsite Backups (Do This First) 🎯

**Goal**: Protect critical data from local disaster

**Steps**:
1. **Choose cloud storage**: Backblaze B2 ($5/TB/month) or rsync.net
2. **Setup automated sync**: Daily backup uploads
3. **Test restore**: Verify you can restore from cloud backups
4. **Cost**: ~$1-3/month

**Script needed**:
- Sync `/mnt/ssd/backups/` to cloud daily
- Keep 30-90 days retention

### Phase 2: Critical Service Replica (Optional)

**Goal**: High availability for password manager and critical services

**Steps**:
1. Deploy VPS (Hetzner CX21 ~$5/month)
2. Setup Vaultwarden + Nextcloud only
3. Sync databases hourly
4. Configure DNS failover or load balancer

**Cost**: ~$5-10/month

### Phase 3: Full Replica (Future - If Needed)

**Goal**: Complete redundancy

**Steps**:
1. Deploy larger VPS
2. Replicate all services
3. Setup automated sync
4. Configure failover

**Cost**: ~$20-50/month depending on storage needs

---

## Cost Comparison

| Option | Monthly Cost | Setup Complexity | Recovery Time | Uptime |
|--------|--------------|------------------|---------------|--------|
| **Offsite Backups Only** | $1-5 | Easy | Hours | Single point of failure |
| **Critical Service Replica** | $5-15 | Medium | Minutes | ~99.9% uptime |
| **Full Replica** | $20-100+ | Hard | Seconds | ~99.99% uptime |

---

## Quick Start: Offsite Backup Setup

### Option 1: Backblaze B2 (Recommended)

```bash
# 1. Install rclone
curl https://rclone.org/install.sh | sudo bash

# 2. Configure (follow prompts)
rclone config
# Name: b2-backup
# Provider: Backblaze B2
# Enter API key and application key from Backblaze dashboard

# 3. Test sync
rclone sync /mnt/ssd/backups/ b2-backup:lemongrab-backups/ --dry-run

# 4. Setup daily sync (add to crontab)
# Run daily at 3 AM (after local backups at 2 AM)
echo "0 3 * * * rclone sync /mnt/ssd/backups/ b2-backup:lemongrab-backups/ --delete-after" | sudo crontab -
```

**Cost**: $5/TB/month (~$0.05/month for 10GB)

### Option 2: rsync.net

```bash
# 1. Setup SSH key
ssh-keygen -t ed25519 -f ~/.ssh/rsync_backup

# 2. Add public key to rsync.net account
cat ~/.ssh/rsync_backup.pub

# 3. Test connection
rsync -avz --dry-run /mnt/ssd/backups/ user@rsync.net:lemongrab-backups/

# 4. Setup daily sync (crontab)
echo "0 3 * * * rsync -avz --delete /mnt/ssd/backups/ user@rsync.net:lemongrab-backups/" | sudo crontab -
```

**Cost**: $2/GB/month (smallest plan)

---

## Replication Sync Strategies

### Critical Services (Vaultwarden, Nextcloud)

**Method**: Database dumps + file sync
- **Frequency**: Hourly or real-time
- **Tool**: `rsync` for files, `pg_dump` + sync for databases

### Media Library (Jellyfin)

**Method**: Incremental sync
- **Frequency**: Daily or on-demand
- **Tool**: `rsync` with `--delete-after` for deletions

### Configuration Files

**Method**: Git repository (already doing this!)
- **Frequency**: On commit
- **Tool**: Git push to GitHub (already set up)

---

## Failover Setup (If Using Replica)

### DNS Failover
1. Setup replica server
2. Configure Cloudflare DNS with multiple A records
3. Use Cloudflare's health checks for automatic failover

### Load Balancing
1. Use Cloudflare Load Balancing
2. Point to primary and replica
3. Automatic failover on health check failure

---

## Monitoring Replication

### What to Monitor:
- ✅ Backup sync success/failure
- ✅ Replica server health
- ✅ Data consistency between primary and replica
- ✅ Storage usage on backup destination

### Tools:
- **Uptime Kuma**: Monitor replica server availability
- **Custom script**: Check backup sync status
- **Cloudflare**: Monitor DNS health checks

---

## Recovery Procedures

### Scenario 1: Primary Server Failure
1. Deploy new server (or use replica)
2. Restore from cloud backups
3. Update DNS/Cloudflare tunnel
4. Verify services

### Scenario 2: Data Corruption
1. Stop affected service
2. Restore from latest backup
3. Restart service
4. Verify data integrity

### Scenario 3: Complete Disaster (Server + Local Backups Lost)
1. Deploy new infrastructure
2. Restore from cloud backups
3. Reconfigure Cloudflare tunnel
4. Test all services

---

## Next Steps

1. **Immediate**: Setup offsite backups (Phase 1)
2. **Short-term**: Test restore procedure
3. **Medium-term**: Consider critical service replica (Phase 2)
4. **Long-term**: Full replica if uptime becomes critical (Phase 3)

---

## Questions to Consider

1. **What's your RTO (Recovery Time Objective)?**
   - Hours? → Offsite backups are fine
   - Minutes? → Need replica
   - Seconds? → Need full HA setup

2. **What's your RPO (Recovery Point Objective)?**
   - Daily? → Daily backups fine
   - Hourly? → Need frequent sync
   - Real-time? → Need replication

3. **Budget?**
   - <$10/month → Offsite backups only
   - $10-50/month → Critical service replica
   - $50+/month → Full replica

4. **Do you need 24/7 uptime?**
   - Personal use? → Backups probably fine
   - Production/critical? → Need replica

---

*Last updated: January 2026*

