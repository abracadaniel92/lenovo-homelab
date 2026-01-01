# Kavita - Ebook Library Setup

## Overview

Kavita is a modern, cross-platform ebook server that allows you to organize, read, and share your ebook collection with others. Perfect for ebook clubs!

## Features

- 📚 **Multiple Formats**: Supports EPUB, PDF, MOBI, CBZ, CBR, and more
- 👥 **User Management**: Create multiple users with different permission levels
- 📖 **Built-in Reader**: Beautiful web-based reader with progress tracking
- 📱 **Mobile Friendly**: Responsive design works great on phones and tablets
- 🔍 **Smart Organization**: Automatic series detection and metadata fetching
- 📊 **Reading Progress**: Track reading progress across devices
- 🎨 **Customizable**: Themes, reading preferences, and more

## Quick Start

### 1. Create Directory Structure

```bash
cd /mnt/ssd/docker-projects
mkdir -p kavita/{data,media,logs}
```

### 2. Copy Docker Compose File

```bash
cp /path/to/repo/docker/kavita/docker-compose.yml /mnt/ssd/docker-projects/kavita/
cd /mnt/ssd/docker-projects/kavita
```

### 3. Start Kavita

```bash
docker compose up -d
```

### 4. Access Kavita

- **Local**: http://localhost:8090
- **Domain**: https://books.gmojsoski.com (after Caddy/Cloudflare setup)

## Initial Setup

1. **First Login**:
   - Default username: `admin`
   - Default password: `admin`
   - ⚠️ **Change this immediately!**

2. **Add Library**:
   - Go to **Admin** → **Libraries**
   - Click **Add Library**
   - Choose a name (e.g., "Ebook Club")
   - Select the folder: `/media` (maps to `./media` on host)
   - Choose library type: **Books**
   - Click **Save**

3. **Add Ebooks**:
   - Copy your ebooks to `/mnt/ssd/docker-projects/kavita/media/`
   - Kavita will automatically scan and organize them
   - Go to **Admin** → **Tasks** → **Scan Library** to trigger a scan

4. **Create Users** (for your ebook club):
   - Go to **Admin** → **Users**
   - Click **Create User**
   - Set username, password, and role
   - **Roles**:
     - **Admin**: Full access
     - **Plebian**: Can read and download
     - **Reader**: Can only read

## Directory Structure

```
/mnt/ssd/docker-projects/kavita/
├── docker-compose.yml
├── data/          # Kavita configuration and database
├── media/         # Your ebooks go here
└── logs/          # Application logs
```

## Adding Ebooks

### Method 1: Direct Copy

```bash
# Copy ebooks to the media directory
cp /path/to/your/ebooks/*.epub /mnt/ssd/docker-projects/kavita/media/
```

### Method 2: Organize by Series

Kavita automatically detects series, but you can organize manually:

```
media/
├── Series Name 1/
│   ├── Book 1.epub
│   ├── Book 2.epub
│   └── Book 3.epub
└── Series Name 2/
    └── Book 1.epub
```

### Method 3: Use Nextcloud (Automated Sync)

Since you have Nextcloud, you can:
1. Upload ebooks to Nextcloud (via web interface or sync client)
2. Run the sync script to automatically copy new books to Kavita:
   ```bash
   cd "/home/goce/Desktop/Cursor projects/Lenovo scripts"
   ./sync-nextcloud-to-kavita.sh
   ```
3. The script will:
   - ✅ Skip existing books (no duplicates)
   - ✅ Copy only new books
   - ✅ Organize by author or preserve folder structure
   - ✅ Show sync summary
4. Then force scan in Kavita to add the new books

**Note:** Update `NEXTCLOUD_BOOKS_DIR` in the script to point to your Nextcloud books folder.

## User Management for Ebook Club

### Creating Club Members

1. Go to **Admin** → **Users**
2. Click **Create User**
3. Fill in:
   - **Username**: Member's name
   - **Email**: (optional)
   - **Password**: Set a secure password
   - **Role**: Choose **Plebian** (can read and download) or **Reader** (read only)
4. Click **Save**

### Sharing Access

Share the URL with your club members:
- **https://books.gmojsoski.com**

Each member can:
- Browse the library
- Read books in the web reader
- Download books (if role allows)
- Track their reading progress
- Create reading lists

## Configuration

### Change Admin Password

1. Login as admin
2. Go to **Admin** → **Users**
3. Click on your user
4. Change password

### Library Settings

- **Admin** → **Libraries** → Click on library → **Edit**
- Configure:
  - **Scan Interval**: How often to scan for new books
  - **Folder Watching**: Auto-detect new files
  - **Metadata**: Enable/disable metadata fetching

### Server Settings

- **Admin** → **Settings** → **Server**
- Configure:
  - **Site Name**: Customize the site title
  - **Port**: Already set to 8090
  - **Logging**: Adjust log levels

## Supported Formats

- **EPUB** (recommended)
- **PDF**
- **MOBI**
- **AZW3**
- **CBZ/CBR** (comics)
- **TXT**

## Mobile Access

Kavita is fully responsive and works great on mobile devices. Members can:
- Read books on their phones/tablets
- Access via browser (no app needed)
- Sync reading progress across devices

## Backup

Important files to backup:

```bash
# Configuration and database
/mnt/ssd/docker-projects/kavita/data/

# Your ebooks
/mnt/ssd/docker-projects/kavita/media/
```

## Troubleshooting

### Books Not Appearing

1. Check file permissions:
   ```bash
   sudo chown -R 1000:1000 /mnt/ssd/docker-projects/kavita/media/
   ```

2. Trigger manual scan:
   - Go to **Admin** → **Tasks** → **Scan Library**

3. Check logs:
   ```bash
   docker logs kavita --tail 50
   ```

### Can't Access from Domain

1. Verify Caddy is routing correctly:
   ```bash
   curl -I http://localhost:8090
   ```

2. Check Cloudflare tunnel:
   ```bash
   systemctl status cloudflared
   ```

3. Verify DNS:
   - Ensure `books.gmojsoski.com` CNAME points to your Cloudflare tunnel

### Performance Issues

- **Large Libraries**: Kavita can handle thousands of books, but initial scan may take time
- **Metadata Fetching**: Disable if you have slow internet
- **File Organization**: Organize books in folders for better performance

## Useful Commands

```bash
# View logs
docker logs kavita --tail 50 -f

# Restart Kavita
docker restart kavita

# Stop Kavita
docker compose down

# Update Kavita
docker compose pull
docker compose up -d

# Check container status
docker ps | grep kavita
```

## Current Configuration

- **Container Name**: `kavita`
- **Port**: `8090` (host) → `5000` (container)
- **Domain**: `books.gmojsoski.com`
- **Data Directory**: `/mnt/ssd/docker-projects/kavita/data`
- **Media Directory**: `/mnt/ssd/docker-projects/kavita/media`
- **Logs Directory**: `/mnt/ssd/docker-projects/kavita/logs`

## Next Steps

1. ✅ Add your first ebook
2. ✅ Create user accounts for club members
3. ✅ Organize books into series/collections
4. ✅ Share the URL with your ebook club
5. ✅ Enjoy reading together!

## Tips for Ebook Club

- **Create Collections**: Organize books by theme, genre, or reading month
- **Use Reading Lists**: Members can create personal reading lists
- **Track Progress**: See what everyone is reading
- **Discussion**: Use Kavita's notes feature or external chat for discussions
- **Regular Updates**: Add new books regularly to keep the library fresh

## Automation Tips

### Reduce Manual Work

1. **Auto-Scan Libraries**:
   - Go to **Admin** → **Settings** → **Tasks**
   - Enable **Scan Library** task (runs daily by default)
   - Kavita will automatically detect new ebooks

2. **Folder Watching** (if supported):
   - Enable automatic folder watching in library settings
   - New files are detected immediately

3. **Bulk Operations**:
   - Use the web interface for bulk actions
   - Select multiple items for batch operations

4. **API Access** (Advanced):
   - Enable API in **Admin** → **Settings** → **API**
   - Use API for automated user creation and library management
   - Scripts available in `Lenovo scripts/` directory

5. **Sync with Nextcloud**:
   - Upload ebooks to Nextcloud
   - Use Nextcloud's file sync or web interface
   - Copy to Kavita media folder when ready

### Quick Setup Workflow

1. **One-time setup** (5 minutes):
   - Create library
   - Set scan schedule
   - Create initial admin user

2. **Adding ebooks** (automated):
   - Copy files to `/mnt/ssd/docker-projects/kavita/media/`
   - Kavita auto-scans daily (or manually trigger)

3. **User management** (as needed):
   - Create users when new members join
   - Or use API for bulk creation

### Recommended Settings

- **Scan Interval**: Daily (default)
- **Metadata Fetching**: Enabled (auto-fetches book info)
- **Series Detection**: Enabled (auto-organizes series)
- **Folder Structure**: Optional - Kavita handles metadata-based organization

