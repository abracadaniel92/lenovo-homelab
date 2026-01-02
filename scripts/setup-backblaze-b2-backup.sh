#!/bin/bash
###############################################################################
# Setup Backblaze B2 Offsite Backup
# Configures rclone to sync backups to Backblaze B2
###############################################################################

set -e

echo "=========================================="
echo "Backblaze B2 Backup Setup"
echo "=========================================="
echo ""

# Check if rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "❌ rclone is not installed!"
    echo "Install it with: curl https://rclone.org/install.sh | sudo bash"
    exit 1
fi

echo "✅ rclone is installed"
echo ""

# Check if already configured
if rclone listremotes | grep -q "b2-backup"; then
    echo "⚠️  Backblaze B2 remote 'b2-backup' already exists!"
    read -p "Do you want to reconfigure it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping configuration..."
        exit 0
    fi
    rclone config delete b2-backup
fi

echo "Step 1: Backblaze B2 Credentials"
echo "----------------------------------------"
echo ""
echo "You need to create a Backblaze B2 bucket and Application Key:"
echo ""
echo "1. Go to: https://secure.backblaze.com/b2_buckets.htm"
echo "2. Create a new bucket (name it: lemongrab-backups)"
echo "3. Go to: https://secure.backblaze.com/b2_buckets.htm -> Application Keys"
echo "4. Create Application Key with:"
echo "   - Name: lemongrab-backups-key"
echo "   - Capabilities: Read and Write"
echo "   - Bucket: lemongrab-backups (or All buckets)"
echo ""
read -p "Press Enter when you have your Application Key ID and Application Key..."

echo ""
echo "Step 2: Configure rclone"
echo "----------------------------------------"
echo ""

# Start rclone configuration
echo "Starting rclone configuration..."
echo "When prompted, enter:"
echo "  - name: b2-backup"
echo "  - storage: 4 (Backblaze B2)"
echo "  - account: (your Application Key ID)"
echo "  - key: (your Application Key)"
echo "  - endpoint: (leave default, press Enter)"
echo ""
read -p "Press Enter to start rclone config..."

rclone config

echo ""
echo "Step 3: Test Connection"
echo "----------------------------------------"
echo ""

# Test listing
echo "Testing connection to Backblaze B2..."
if rclone lsd b2-backup: 2>/dev/null; then
    echo "✅ Connection successful!"
else
    echo "❌ Connection failed. Please check your credentials."
    exit 1
fi

echo ""
echo "Step 4: Create Backup Directory"
echo "----------------------------------------"
echo ""

# Create backup directory structure
rclone mkdir b2-backup:lemongrab-backups 2>/dev/null || true
echo "✅ Backup directory created"

echo ""
echo "Step 5: Test Sync (Dry Run)"
echo "----------------------------------------"
echo ""

BACKUP_DIR="/mnt/ssd/backups"
if [ ! -d "$BACKUP_DIR" ]; then
    echo "⚠️  Backup directory not found: $BACKUP_DIR"
    echo "   Adjust BACKUP_DIR in the script if your backups are elsewhere"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Running dry-run test (no files will be uploaded)..."
rclone sync "$BACKUP_DIR/" b2-backup:lemongrab-backups/ --dry-run --progress 2>&1 | tail -20

echo ""
read -p "Does this look correct? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled. You can run rclone config to fix settings."
    exit 1
fi

echo ""
echo "Step 6: First Real Sync"
echo "----------------------------------------"
echo ""

echo "Uploading backups to Backblaze B2 (this may take a few minutes)..."
rclone sync "$BACKUP_DIR/" b2-backup:lemongrab-backups/ --progress

echo ""
echo "Step 7: Setup Automated Daily Sync"
echo "----------------------------------------"
echo ""

# Create sync script
SYNC_SCRIPT="/usr/local/bin/sync-backups-to-b2.sh"
sudo tee "$SYNC_SCRIPT" > /dev/null << EOF
#!/bin/bash
# Sync backups to Backblaze B2
# Runs daily after local backups complete (3 AM)

LOG_FILE="/var/log/rclone-sync.log"
BACKUP_DIR="/mnt/ssd/backups"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting B2 sync..." >> "\$LOG_FILE"
rclone sync "\$BACKUP_DIR/" b2-backup:lemongrab-backups/ --delete-after --log-file="\$LOG_FILE" --log-level INFO 2>&1

if [ \$? -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync completed successfully" >> "\$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] B2 sync FAILED!" >> "\$LOG_FILE"
fi
EOF

sudo chmod +x "$SYNC_SCRIPT"
echo "✅ Sync script created: $SYNC_SCRIPT"

# Add to crontab
echo ""
echo "Adding to crontab (runs daily at 3 AM, after local backups at 2 AM)..."
(crontab -l 2>/dev/null | grep -v "sync-backups-to-b2.sh"; echo "0 3 * * * $SYNC_SCRIPT") | crontab -
echo "✅ Crontab entry added"

echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - rclone configured: b2-backup"
echo "  - Remote location: b2-backup:lemongrab-backups/"
echo "  - Sync script: $SYNC_SCRIPT"
echo "  - Automated sync: Daily at 3:00 AM"
echo "  - Log file: /var/log/rclone-sync.log"
echo ""
echo "Manual commands:"
echo "  - Sync now: rclone sync /mnt/ssd/backups/ b2-backup:lemongrab-backups/"
echo "  - List files: rclone ls b2-backup:lemongrab-backups/"
echo "  - Check logs: tail -f /var/log/rclone-sync.log"
echo ""
echo "Verify backup:"
echo "  rclone ls b2-backup:lemongrab-backups/"
echo ""

