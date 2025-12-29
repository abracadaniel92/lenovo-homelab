# Nextcloud Fresh Installation Guide

## ✅ Files Backed Up

Your Nextcloud user files have been successfully backed up!

**Backup Location:** `/mnt/ssd/backups/nextcloud-files-20251229-154047`

**Backed Up Users:**
- `admin` (36M)
- `aposohin` (36M)
- `gmojsoski` (101M) - Main account with all folders
- Plus backup directories (aposohin.backup, gmojsoski.backup, etc.)

**Total Backup Size:** 378MB

**File Structure:**
- User files are in: `/mnt/ssd/backups/nextcloud-files-20251229-154047/USERNAME/files/`
- Example: `/mnt/ssd/backups/nextcloud-files-20251229-154047/gmojsoski/files/` contains:
  - AI Prompts/
  - Books/
  - Coding/
  - Documents/
  - Movies To Watch/
  - Nextcloud intro/
  - Notes/
  - Photos/
  - Talk/
  - Tattoos/
  - Templates/
  - Usefull Stuff/
  - Work/

## 🔄 Fresh Installation Steps

### Step 1: Run Fresh Install Script

```bash
cd "/home/goce/Desktop/Cursor projects/Lenovo scripts"
./fresh-install-nextcloud.sh
```

This will:
- Stop Nextcloud containers
- Remove old database (accounts will be lost)
- Remove old app files
- Start fresh Nextcloud installation

### Step 2: Complete Setup Wizard

1. Open http://localhost:8081 in your browser
2. You'll see the Nextcloud setup wizard
3. Enter:
   - **Admin username**: (choose one, e.g., `admin`)
   - **Admin password**: (create a strong password)
   - **Database**: PostgreSQL
   - **Database user**: `nextcloud`
   - **Database password**: `change_me_strong`
   - **Database name**: `nextcloud`
   - **Database host**: `db`
4. Click "Finish setup"

### Step 2.5: Configure Domain (After Installation)

After installation, configure the domain for external access:

```bash
# Add trusted domain
docker exec nextcloud-app php /var/www/html/occ config:system:set trusted_domains 0 --value=localhost
docker exec nextcloud-app php /var/www/html/occ config:system:set trusted_domains 1 --value=cloud.gmojsoski.com

# Set overwrite host and protocol
docker exec nextcloud-app php /var/www/html/occ config:system:set overwritehost --value=cloud.gmojsoski.com
docker exec nextcloud-app php /var/www/html/occ config:system:set overwriteprotocol --value=https
```

**Note:** The docker-compose.yml already has environment variables for these, but they may not always apply during fresh install. Use the OCC commands above to ensure they're set correctly.

### Step 3: Restore Your Files

After completing the setup wizard, restore your files:

```bash
cd "/home/goce/Desktop/Cursor projects/Lenovo scripts"
./restore-nextcloud-files.sh
```

The script will:
- Find the most recent backup
- List available users
- Ask which users to restore
- Create users if they don't exist
- Copy files from backup
- Fix ownership
- Scan files so they appear in Nextcloud

**Or restore manually via web interface:**

1. Log in to Nextcloud at `https://cloud.gmojsoski.com` or `http://localhost:8081`
2. Create user accounts matching the backup directory names (if not already created)
3. Navigate to Files app
4. Copy files from backup location:
   ```
   /mnt/ssd/backups/nextcloud-files-20251229-154047/gmojsoski/files/
   ```
5. Upload via drag & drop or upload button in Nextcloud web interface

**Or restore manually via command line:**

1. Create user accounts in Nextcloud matching the backup directory names:
   ```bash
   docker exec nextcloud-app php /var/www/html/occ user:add gmojsoski
   docker exec nextcloud-app php /var/www/html/occ user:add aposohin
   ```

2. Copy files from backup:
   ```bash
   docker cp /mnt/ssd/backups/nextcloud-files-20251229-154047/gmojsoski nextcloud-app:/var/www/html/data/gmojsoski
   docker cp /mnt/ssd/backups/nextcloud-files-20251229-154047/aposohin nextcloud-app:/var/www/html/data/aposohin
   ```

3. Fix ownership:
   ```bash
   docker exec nextcloud-app chown -R www-data:www-data /var/www/html/data/gmojsoski
   docker exec nextcloud-app chown -R www-data:www-data /var/www/html/data/aposohin
   ```

4. Scan files:
   ```bash
   docker exec nextcloud-app php /var/www/html/occ files:scan --all
   ```

## 📁 File Locations

- **Backup**: `/mnt/ssd/backups/nextcloud-files-20251229-154047/`
- **Nextcloud Data**: `/mnt/ssd/apps/nextcloud/app/data/`
- **Nextcloud Config**: `/mnt/ssd/apps/nextcloud/docker-compose.yml`
- **Nextcloud App Files**: `/mnt/ssd/apps/nextcloud/app/`
- **Database**: `/mnt/ssd/apps/nextcloud/db/`

## 🌐 Domain Configuration

- **Local Access**: http://localhost:8081
- **External Access**: https://cloud.gmojsoski.com
- **Caddy Routing**: `cloud.gmojsoski.com` → `http://172.17.0.1:8081`
- **Cloudflare Tunnel**: `cloud.gmojsoski.com` → `http://localhost:8080` (Caddy)

## ✅ Current Installation Status (Dec 29, 2025)

- **Version**: Nextcloud 30.0.17.2 (latest)
- **Database**: PostgreSQL 16
- **Status**: ✅ Installed and running
- **Trusted Domains**: localhost, cloud.gmojsoski.com
- **Overwrite Host**: cloud.gmojsoski.com
- **Overwrite Protocol**: https

## ⚠️ Important Notes

1. **Accounts are NOT backed up** - You'll need to recreate user accounts
2. **Files ARE backed up** - All your files are safe in the backup
3. **Database is reset** - All metadata (shares, settings, etc.) will be lost
4. **Files will be restored** - After creating accounts, files will be restored

## 🔍 Troubleshooting

### Can't access setup wizard
```bash
# Check if containers are running
docker ps | grep nextcloud

# Check logs
docker logs nextcloud-app
docker logs nextcloud-postgres
```

### Files don't appear after restore
```bash
# Re-scan files
docker exec nextcloud-app php /var/www/html/occ files:scan --all

# Check file ownership
docker exec nextcloud-app ls -la /var/www/html/data/USERNAME
```

### Need to access backup manually
The backup is at: `/mnt/ssd/backups/nextcloud-files-20251229-154047/`

You can browse it like any directory:
```bash
ls -lh /mnt/ssd/backups/nextcloud-files-20251229-154047/
```

### "Untrusted Domain" Error
If you see "Access through untrusted domain" error when accessing via `cloud.gmojsoski.com`:

```bash
# Add the domain to trusted domains
docker exec nextcloud-app php /var/www/html/occ config:system:set trusted_domains 1 --value=cloud.gmojsoski.com

# Verify it was added
docker exec nextcloud-app php /var/www/html/occ config:system:get trusted_domains
```

### 503 Service Unavailable
If you get a 503 error after fresh install:

1. Check if containers are running:
   ```bash
   docker ps | grep nextcloud
   ```

2. Check logs:
   ```bash
   docker logs nextcloud-app --tail 50
   ```

3. Ensure config.php doesn't exist before setup:
   ```bash
   docker exec nextcloud-app rm -f /var/www/html/config/config.php
   rm -f /mnt/ssd/apps/nextcloud/app/config/config.php
   docker restart nextcloud-app
   ```

4. If old files persist, clean with Docker:
   ```bash
   cd /mnt/ssd/apps/nextcloud
   docker compose down
   docker run --rm -v /mnt/ssd/apps/nextcloud/app:/cleanup -w /cleanup alpine sh -c "rm -rf * .[^.]* && mkdir -p data config"
   docker compose up -d
   ```

