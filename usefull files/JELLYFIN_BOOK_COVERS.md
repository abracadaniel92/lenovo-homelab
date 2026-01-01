# Jellyfin Book Covers Setup

## Problem
Book covers are not showing in Jellyfin.

## Solution

### Step 1: Configure Metadata Providers

1. **Open Jellyfin**: https://jellyfin.gmojsoski.com
2. **Login as admin**
3. **Go to Dashboard** → **Libraries**
4. **Click on your Books library** (or create one if it doesn't exist)
5. **Click "Edit"** (pencil icon)
6. **Scroll to "Metadata" section**
7. **Enable metadata providers** (in order of preference):
   - ✅ **OpenLibrary** (best for books)
   - ✅ **Google Books**
   - ✅ **Audible** (if you have audiobooks)
   - ✅ **TheTVDB** (optional, mainly for TV)
   - ✅ **TheMovieDb** (optional, mainly for movies)

8. **Set download options**:
   - ✅ **Download images in advance**
   - ✅ **Save artwork into media folders**

9. **Click "Save"**

### Step 2: Create/Configure Books Library

If you don't have a Books library yet:

1. **Dashboard** → **Libraries** → **Add Media Library**
2. **Content type**: Select **"Books"**
3. **Display name**: "Books"
4. **Folders**: Click **"+"** and add `/media/books`
5. **Metadata**: Configure as above
6. **Click "OK"**

### Step 3: Refresh Metadata for Existing Books

1. **Go to your Books library**
2. **Click the three dots (⋮)** in the top right
3. **Select "Refresh Metadata"**
4. **Choose**:
   - ✅ **Replace all metadata**
   - ✅ **Replace images**
5. **Click "OK"**

This will download covers from metadata providers for all your books.

### Step 4: Manual Cover Addition (If Metadata Doesn't Work)

If metadata providers don't find covers, you can add them manually:

1. **For each book**, create a folder structure:
   ```
   /media/books/Book Title/
   ├── Book Title.epub
   └── cover.jpg (or cover.png)
   ```

2. **Download cover image** from:
   - Google Books
   - OpenLibrary
   - Amazon
   - Goodreads

3. **Save as `cover.jpg`** in the book's folder

4. **Refresh metadata** for that book in Jellyfin

### Step 5: Verify Covers Are Embedded in EPUBs

Some EPUB files have covers embedded. To check:

```bash
# Check if EPUB has embedded cover
epub-info /mnt/ssd/docker-projects/jellyfin/media/books/your-book.epub
```

Jellyfin should automatically extract embedded covers.

## Quick Fix: Refresh All Books

**Fastest way to get covers for all books:**

1. **Dashboard** → **Libraries** → **Books library** → **Edit**
2. **Metadata** → Enable **OpenLibrary** and **Google Books**
3. **Save**
4. **Go to Books library**
5. **Three dots (⋮)** → **Refresh Metadata** → **Replace all metadata** + **Replace images**
6. **Wait for scan to complete** (may take a few minutes)

## Troubleshooting

### Covers Still Not Showing

1. **Check library type**:
   - Must be set to **"Books"** content type
   - Not "Mixed Content" or "Music"

2. **Check metadata providers are enabled**:
   - Dashboard → Libraries → Books → Edit → Metadata
   - Ensure OpenLibrary and Google Books are checked

3. **Check file permissions**:
   ```bash
   ls -la /mnt/ssd/docker-projects/jellyfin/media/books/
   ```
   - Files should be readable by Jellyfin (user 1000:1000)

4. **Check Jellyfin logs**:
   ```bash
   docker logs jellyfin --tail 50 | grep -i cover
   docker logs jellyfin --tail 50 | grep -i metadata
   ```

5. **Force refresh**:
   - Remove library and re-add it
   - Or restart Jellyfin: `docker restart jellyfin`

### Metadata Providers Not Working

1. **Check internet connectivity** from Jellyfin container:
   ```bash
   docker exec jellyfin ping -c 3 openlibrary.org
   docker exec jellyfin ping -c 3 books.google.com
   ```

2. **Check if providers are accessible**:
   - Jellyfin needs internet access to download metadata
   - If behind a firewall, ensure Jellyfin can reach metadata providers

### Covers Show in Web But Not Mobile App

1. **Clear mobile app cache**
2. **Restart mobile app**
3. **Refresh library in mobile app**

## Best Practices

1. **Organize books in folders** (optional but recommended):
   ```
   /media/books/
   ├── Author Name/
   │   ├── Book Title.epub
   │   └── cover.jpg
   ```

2. **Use consistent naming**:
   - `Author - Book Title.epub` works well
   - Jellyfin will try to match with metadata providers

3. **Keep covers updated**:
   - Periodically refresh metadata to get updated covers
   - Or manually update covers if metadata doesn't match

## Metadata Provider Priority

Jellyfin checks providers in this order (if enabled):
1. **OpenLibrary** - Best for books, free, comprehensive
2. **Google Books** - Good coverage, high-quality images
3. **Audible** - For audiobooks
4. **Embedded metadata** - From EPUB files themselves

## Expected Results

After configuration:
- ✅ Book covers appear in library view
- ✅ Covers show in detail view
- ✅ Covers display in mobile app
- ✅ Covers are cached for offline viewing

## Quick Commands

```bash
# Check books directory
ls -la /mnt/ssd/docker-projects/jellyfin/media/books/

# Check Jellyfin container
docker ps | grep jellyfin

# View Jellyfin logs
docker logs jellyfin --tail 100

# Restart Jellyfin
docker restart jellyfin
```




