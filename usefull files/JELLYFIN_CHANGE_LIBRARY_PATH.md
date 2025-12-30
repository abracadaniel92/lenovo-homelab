# How to Change Jellyfin Library Path from /media to /media/music

## Step 1: Move Music Files (if needed)

If you have music files directly in `/media/`, move them to `/media/music/`:

```bash
# Move all music files from /media/ to /media/music/
mv /mnt/ssd/docker-projects/jellyfin/media/*.mp3 /mnt/ssd/docker-projects/jellyfin/media/music/ 2>/dev/null
mv /mnt/ssd/docker-projects/jellyfin/media/*.flac /mnt/ssd/docker-projects/jellyfin/media/music/ 2>/dev/null
mv /mnt/ssd/docker-projects/jellyfin/media/*.m4a /mnt/ssd/docker-projects/jellyfin/media/music/ 2>/dev/null
mv /mnt/ssd/docker-projects/jellyfin/media/*.ogg /mnt/ssd/docker-projects/jellyfin/media/music/ 2>/dev/null
mv /mnt/ssd/docker-projects/jellyfin/media/*.wav /mnt/ssd/docker-projects/jellyfin/media/music/ 2>/dev/null

# Or move entire folders if you have artist/album folders
mv /mnt/ssd/docker-projects/jellyfin/media/*/ /mnt/ssd/docker-projects/jellyfin/media/music/ 2>/dev/null
```

**Note:** Only move files if they exist. If `/media/` is empty or only has the subdirectories (music/, movies/, etc.), skip this step.

## Step 2: Update Library in Jellyfin Web Interface

1. **Open Jellyfin:**
   - Go to: `https://jellyfin.gmojsoski.com`
   - Login with your admin account

2. **Navigate to Libraries:**
   - Click your **profile icon** (top right corner)
   - Click **Dashboard**
   - Click **Libraries** (in the left sidebar)

3. **Edit Music Library:**
   - Find your **Music** library in the list
   - Click the **pencil/edit icon** (or three dots menu → Edit)

4. **Change Folder Path:**
   - In the "Folders" section, you'll see: `/media`
   - Click the **X** or **Remove** button next to `/media`
   - Click **Add Folder**
   - Enter: `/media/music`
   - Click **OK** or **Add**

5. **Save Changes:**
   - Click **Save** or **OK**
   - Jellyfin will automatically rescan the library

## Step 3: Verify

1. Go to your **Music** library in Jellyfin
2. Check that all your music is still there
3. If anything is missing, check the file locations

## Alternative: Using Jellyfin API (Advanced)

If you prefer command line:

```bash
# This requires Jellyfin API token - easier to use web UI
```

## Troubleshooting

### Files Not Showing After Change
- Make sure files are in `/mnt/ssd/docker-projects/jellyfin/media/music/` on the host
- Check file permissions (should be readable)
- Trigger manual library scan: Dashboard → Libraries → Music → Scan Library

### Library Path Not Saving
- Make sure path starts with `/media/music` (not `/mnt/ssd/...`)
- Path must be inside the container, not the host path
- Try removing and re-adding the library if it won't save

## Summary

**Quick Steps:**
1. Move files: `/media/` → `/media/music/` (if needed)
2. Jellyfin Web UI: Dashboard → Libraries → Edit Music → Change path to `/media/music`
3. Save and wait for rescan

That's it! Your music library will now point to `/media/music`.

