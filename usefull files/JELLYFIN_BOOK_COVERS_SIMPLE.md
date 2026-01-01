# Jellyfin Book Covers - Simple Guide

## Step 1: Install Bookshelf Plugin

1. **Open Jellyfin**: https://jellyfin.gmojsoski.com
2. **Click your profile icon** (top right corner)
3. **Click "Dashboard"**
4. **In the left sidebar**, click **"Plugins"**
5. **Click "Catalog"** tab
6. **Search for "Bookshelf"**
7. **Click "Install"** on the Bookshelf plugin
8. **Wait for installation** to complete

## Step 2: Create/Configure Books Library

1. **Still in Dashboard**, click **"Libraries"** in the left sidebar
2. **If you don't have a Books library yet:**
   - Click **"Add Media Library"** button
   - **Content Type**: Select **"Books"**
   - **Display Name**: "Books"
   - **Folders**: Click **"+"** and browse to `/media/books`
   - Click **"OK"**

3. **If you already have a Books library:**
   - Click on your **Books library** to edit it
   - Make sure **Content Type** is set to **"Books"**

## Step 3: Enable Metadata Providers

1. **In your Books library settings**, scroll down to find **"Metadata"** section
2. **Enable these providers** (drag to reorder priority):
   - ✅ **OpenLibrary** (best for books)
   - ✅ **Google Books**
3. **Check these options**:
   - ✅ **Download images in advance**
   - ✅ **Save artwork into media folders**
4. **Click "Save"**

## Step 4: Refresh Metadata to Get Covers

1. **Go to your Books library** (click it in the main menu)
2. **Click the three dots (⋮)** menu at the top right
3. **Click "Refresh Metadata"**
4. **Check both boxes**:
   - ✅ **Replace all metadata**
   - ✅ **Replace images**
5. **Click "OK"**
6. **Wait** for the scan to complete (may take a few minutes)

## That's It!

After the refresh completes, book covers should appear. If some books still don't have covers, the metadata providers might not have them. You can manually add covers later.

## Quick Troubleshooting

**Can't find "Plugins"?**
- Make sure you're logged in as **admin**
- Click your profile icon → Dashboard → Look in left sidebar

**Can't find "Libraries"?**
- Dashboard → Left sidebar → "Libraries"
- Or: Profile icon → Dashboard → Scroll down to "Libraries" section

**Bookshelf plugin not showing?**
- Make sure Jellyfin has internet access
- Try refreshing the plugins catalog
- Check Jellyfin version (needs to be recent)

**Still no covers after refresh?**
- Some books might not be in metadata databases
- You can manually add covers (see main guide)
- Or wait - metadata providers update regularly


