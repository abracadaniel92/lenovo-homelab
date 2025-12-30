# Jellyfin Books Library Setup

## Problem
Books are in `/mnt/ssd/docker-projects/jellyfin/media/books/` but not showing in Jellyfin.

## Diagnosis
✅ Files exist on host: `/mnt/ssd/docker-projects/jellyfin/media/books/`  
✅ Files accessible in container: `/media/books/`  
❌ Jellyfin logs show: "Library folder /media/books is inaccessible or empty, skipping"

## Solution

The library needs to be **added in Jellyfin's web UI**. The files are there, but Jellyfin doesn't know to scan them.

### Steps to Add Books Library:

1. **Access Jellyfin Web UI**
   - Go to: `https://jellyfin.gmojsoski.com`
   - Login with your admin account

2. **Go to Dashboard → Libraries**
   - Click on your user icon (top right)
   - Select "Dashboard"
   - Click "Libraries" in the left menu

3. **Add New Library**
   - Click the "+" button (Add Media Library)
   - Select **"Books"** as the content type
   - Click "OK"

4. **Configure Library Path**
   - Click "Add Folder"
   - Enter the path: `/media/books`
   - Click "OK"
   - Click "OK" again to save the library

5. **Trigger Library Scan**
   - After adding the library, Jellyfin should automatically start scanning
   - If not, go to Dashboard → Scheduled Tasks
   - Find "Scan Media Library" and click "Run Now"

6. **Verify Books Appear**
   - Go to the main Jellyfin page
   - Click on "Books" in the left menu
   - Your books should now appear!

## Alternative: Use CLI to Add Library

If you prefer command line, you can use Jellyfin's API:

```bash
# Get API key from Jellyfin web UI (Dashboard → API Keys)
API_KEY="your-api-key-here"
JELLYFIN_URL="http://localhost:8096"

# Add books library
curl -X POST "${JELLYFIN_URL}/Library/VirtualFolders" \
  -H "X-Emby-Authorization: MediaBrowser Client=\"Jellyfin\", Device=\"CLI\", DeviceId=\"cli\", Version=\"1.0.0\", Token=\"${API_KEY}\"" \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "Books",
    "CollectionType": "books",
    "LibraryOptions": {
      "PathInfos": [
        {
          "Path": "/media/books"
        }
      ]
    }
  }'
```

## Verify Files Are Accessible

```bash
# Check files in container
docker exec jellyfin ls -la /media/books/ | head -10

# Check file count
docker exec jellyfin find /media/books -name "*.epub" | wc -l
```

## Troubleshooting

### If books still don't appear:

1. **Check Library Type**
   - Make sure you selected "Books" (not "Mixed Content")
   - Books library type enables book-specific features

2. **Check Permissions**
   ```bash
   # Files should be readable by user 1000
   docker exec jellyfin ls -la /media/books/ | head -5
   ```

3. **Force Library Scan**
   - Dashboard → Scheduled Tasks → "Scan Media Library" → "Run Now"
   - Or wait for automatic scan (runs periodically)

4. **Check Logs**
   ```bash
   docker logs jellyfin --tail 50 | grep -i "book\|library"
   ```

5. **Restart Jellyfin**
   ```bash
   docker restart jellyfin
   ```

## Current Status

- ✅ Books folder exists: `/mnt/ssd/docker-projects/jellyfin/media/books/`
- ✅ Files present: Multiple `.epub` files detected
- ✅ Container can access: `/media/books/` is mounted correctly
- ⚠️  Library not configured: Need to add in Jellyfin web UI

## Next Steps

1. Access Jellyfin web UI: `https://jellyfin.gmojsoski.com`
2. Add Books library pointing to `/media/books`
3. Wait for scan to complete (or trigger manually)
4. Books should appear in the Books section!

