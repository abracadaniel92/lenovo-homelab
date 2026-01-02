# Cheapest Phase 1 Offsite Backup Options

## Your Backup Size
- **Current backups**: ~400MB (critical data only)
- **Future growth**: Probably stay under 1GB for critical data
- **Media (optional)**: ~5GB music, but can backup separately if needed

---

## Cheapest Options Ranked (For ~400MB-1GB)

### 🥇 Winner: Backblaze B2 (CHEAPEST)
**Price**: **$0.005/GB/month** = **~$0.20/month for 400MB**
- First **10GB FREE** (never pay for your use case!)
- **$5/TB/month** after that
- **Free egress** (downloads) up to 3x storage
- Compatible with rclone, restic, etc.
- **Total Cost**: **$0/month** (you'll never exceed free tier!)

**Setup**: rclone with B2 backend

---

### 🥈 Second: rsync.net
**Price**: **$2/GB/month** = **~$0.80/month for 400MB**
- More expensive but simple
- Direct rsync/SSH access
- Good for small amounts
- **Total Cost**: **~$1/month**

---

### 🥉 Third: DigitalOcean Spaces
**Price**: **$5/month + $0.02/GB** = **~$5.01/month**
- **5GB free**, then pay per GB
- $5 base fee (not worth it for small backups)

---

### Other Options (Not Recommended for Small Backups)

| Service | Price | Why Not |
|---------|-------|---------|
| AWS S3 | $0.023/GB + requests | Too complex, minimum charges |
| Google Cloud Storage | Similar to S3 | Complex setup |
| Wasabi | $6.99/TB (~$0.007/GB) | $5.99 minimum fee |
| Cloudflare R2 | $0.015/GB | Good but Backblaze is cheaper |

---

## 🏆 Recommended: Backblaze B2 (FREE for you!)

**Why it wins:**
- ✅ **Completely FREE** for your backup size (<10GB)
- ✅ Easy setup with rclone
- ✅ Fast uploads/downloads
- ✅ Reliable (used by many companies)
- ✅ No hidden fees
- ✅ Free egress (downloads) up to 3x storage per day

**Even if your backups grow to 10GB**, it's still only **$0.05/month**!

---

## Quick Setup: Backblaze B2 (Free Option)

### Step 1: Create Backblaze Account
1. Go to: https://www.backblaze.com/b2/sign-up.html
2. Sign up (free account)
3. Create a **B2 Cloud Storage** bucket
4. Create **Application Key** (note down the keyID and applicationKey)

### Step 2: Install rclone
```bash
curl https://rclone.org/install.sh | sudo bash
```

### Step 3: Configure rclone
```bash
rclone config
# Choose: n) New remote
# Name: b2-backup
# Storage: 4 (Backblaze B2)
# Account ID: (from Backblaze dashboard)
# Application Key: (from Backblaze)
# Endpoint: (leave default)
# Use 1 (yes) for everything else
```

### Step 4: Test Sync
```bash
# Test (dry run - won't actually upload)
rclone sync /mnt/ssd/backups/ b2-backup:lemongrab-backups/ --dry-run

# Real sync
rclone sync /mnt/ssd/backups/ b2-backup:lemongrab-backups/
```

### Step 5: Setup Daily Automated Sync
```bash
# Create sync script
cat > /usr/local/bin/sync-backups-to-b2.sh << 'EOF'
#!/bin/bash
# Sync backups to Backblaze B2 (runs after local backups)
/usr/bin/rclone sync /mnt/ssd/backups/ b2-backup:lemongrab-backups/ --delete-after --log-file=/var/log/rclone-sync.log
EOF

sudo chmod +x /usr/local/bin/sync-backups-to-b2.sh

# Add to crontab (runs at 3 AM, after local backups at 2 AM)
echo "0 3 * * * /usr/local/bin/sync-backups-to-b2.sh" | sudo crontab -
```

### Step 6: Verify
```bash
# Check what's uploaded
rclone ls b2-backup:lemongrab-backups/

# Test download
rclone copy b2-backup:lemongrab-backups/vaultwarden/ /tmp/test-restore/ --dry-run
```

---

## Cost Breakdown

| Backup Size | Backblaze B2 | rsync.net | DigitalOcean |
|-------------|--------------|-----------|--------------|
| 400MB | **$0.00** ✅ | $0.80 | $5.01 |
| 1GB | **$0.01** ✅ | $2.00 | $5.02 |
| 5GB | **$0.03** ✅ | $10.00 | $5.10 |
| 10GB | **$0.05** ✅ | $20.00 | $5.20 |

**Backblaze B2 is the clear winner for your use case!**

---

## Alternative: Free Options (If Budget is Zero)

### Option 1: GitHub LFS (Free 1GB)
- Can store backups in private GitHub repo
- **Free tier**: 1GB storage + 1GB bandwidth/month
- Works for critical configs, but not for full backups

### Option 2: Google Drive / Dropbox (Free Tier)
- **15GB free** on Google Drive
- Can use rclone to sync
- **Limitation**: Personal account, TOS may not allow server backups

### Option 3: Another Server You Own
- Use your Raspberry Pi 4 (Pi-hole server)
- Setup rsync to sync backups there
- **Cost**: $0 (you own the hardware)

---

## Recommendation

**Use Backblaze B2**:
- ✅ **FREE** for your backup size
- ✅ Professional, reliable service
- ✅ Easy to restore from
- ✅ Can scale if needed (still cheap)
- ✅ Industry standard

**Setup time**: 15 minutes  
**Monthly cost**: **$0**  
**Protection level**: High

---

*Last updated: January 2026*

