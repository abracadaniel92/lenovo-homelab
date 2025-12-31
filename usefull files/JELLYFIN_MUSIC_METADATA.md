# Jellyfin Music Metadata and Album Covers Setup

## Overview
Jellyfin automatically fetches album covers, artist images, and metadata for music files. Unlike books, no plugins are required - it's built-in!

## Step 1: Verify Music Library Configuration

1. **Go to Jellyfin Dashboard**
   - Navigate to `https://jellyfin.gmojsoski.com`
   - Log in as admin

2. **Check Library Settings**
   - Dashboard → Libraries
   - Click on your **Music** library
   - Click **Edit** (pencil icon)

3. **Verify Content Type**
   - Ensure **Content type** is set to **"Music"**
   - This should already be set if you created it as a music library

## Step 2: Enable Metadata Providers

1. **Go to Metadata Settings**
   - Dashboard → Libraries → Music library → Edit
   - Scroll to **Metadata** section

2. **Enable Metadata Providers**
   - Check the following providers:
     - **MusicBrainz** (primary source for music metadata)
     - **TheAudioDB** (album covers and artist images)
     - **AudioDB** (backup metadata source)
   
3. **Enable Image Providers**
   - Under **Image providers**, ensure:
     - **TheAudioDB** is enabled
     - **MusicBrainz** is enabled (for artist images)

## Step 3: Configure Metadata Preferences

1. **In the same Metadata section:**
   - **Preferred metadata language**: Set to your preference (e.g., "English")
   - **Album art**: Should be enabled by default
   - **Artist images**: Should be enabled by default

2. **Save Settings**
   - Click **Save** at the bottom

## Step 4: Refresh Library Metadata

1. **Scan Library**
   - Go to Dashboard → Libraries → Music
   - Click **⋮** (three dots menu) → **Scan Library**
   - This will scan for new files

2. **Refresh Metadata**
   - Click **⋮** (three dots menu) → **Refresh Metadata**
   - Choose:
     - **Replace all metadata** (if you want to re-fetch everything)
     - **Replace missing metadata** (if you only want to fill gaps)
   
   - **Recommended**: Start with "Replace missing metadata" first

3. **Wait for Completion**
   - This may take several minutes depending on the number of files
   - You can monitor progress in Dashboard → Scheduled Tasks

## Step 5: Verify Results

1. **Check Albums**
   - Go to Music library
   - Albums should now show:
     - Album covers
     - Artist names
     - Release dates
     - Track listings

2. **Check Artists**
   - Go to Artists view
   - Should show:
     - Artist images/thumbnails
     - Album counts
     - Discography

## Troubleshooting

### No Album Covers Showing

1. **Check File Organization**
   - Jellyfin works best with: `Artist/Album/Track.mp3`
   - Your files are currently flat in `/media/music/`
   - **Solution**: Jellyfin can still fetch metadata from embedded tags or online sources

2. **Check Embedded Metadata**
   - Your MP3 files may already have embedded album art
   - Jellyfin will use embedded art if available
   - If not, it will fetch from TheAudioDB/MusicBrainz

3. **Manual Refresh**
   - Right-click on an album → **Refresh Metadata**
   - Or go to album → Edit → **Refresh Metadata**

### Missing Artist Images

1. **Enable Artist Image Provider**
   - Dashboard → Libraries → Music → Edit → Metadata
   - Ensure **TheAudioDB** is enabled for artist images

2. **Refresh Artist Metadata**
   - Go to Artists view
   - Right-click artist → **Refresh Metadata**

### Some Albums Not Found

1. **Check File Tags**
   - Files need proper ID3 tags (Artist, Album, Title)
   - If tags are missing, Jellyfin can't match to metadata

2. **Manual Identification**
   - Right-click album → **Identify**
   - Search for the correct album
   - Select and save

3. **Embed Album Art Manually**
   - You can add `folder.jpg` or `cover.jpg` to album folders
   - But since files are flat, this won't work
   - Better to let Jellyfin fetch from online sources

## File Organization (Optional)

If you want better organization later, you could organize files as:
```
/music/
  Artist Name/
    Album Name/
      Track 01.mp3
      Track 02.mp3
      folder.jpg (optional)
```

But for now, Jellyfin will work with flat files if they have proper ID3 tags.

## Quick Reference

**Location of music files:**
- `/mnt/ssd/docker-projects/jellyfin/media/music/`

**Refresh library:**
- Dashboard → Libraries → Music → ⋮ → Refresh Metadata

**Check metadata providers:**
- Dashboard → Libraries → Music → Edit → Metadata section

