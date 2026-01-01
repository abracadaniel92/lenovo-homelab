# Adding Manual Book Covers in Jellyfin

## Why Some Books Don't Have Covers

It's **normal** that not all books have covers! Metadata providers (OpenLibrary, Google Books) don't have covers for:
- Older or obscure books
- Self-published books
- Books with unusual titles
- Books not in their databases

## Method 1: Upload Cover via Jellyfin UI (Easiest)

1. **Go to your Books library**
2. **Click on a book** that's missing a cover
3. **Click the three dots (⋮)** menu
4. **Click "Edit Metadata"**
5. **Click "Images" tab**
6. **Click "Add Image"** or drag & drop
7. **Upload the cover image** (download from Google Books, Amazon, etc.)
8. **Click "Save"**

## Method 2: Add Cover File to Book Folder

### Step 1: Download Cover Image
- **Google Books**: Search for the book → Right-click cover → Save image
- **Amazon**: Product page → Right-click cover → Save image
- **OpenLibrary**: https://openlibrary.org → Search book → Download cover
- **Goodreads**: Book page → Cover image → Save

### Step 2: Organize Book Files

**Option A: Single Book in Folder**
```
/media/books/
└── Book Title/
    ├── Book Title.epub
    └── cover.jpg (or cover.png)
```

**Option B: Keep Flat Structure**
```
/media/books/
├── Book Title.epub
└── Book Title - cover.jpg
```

### Step 3: Refresh Metadata

1. **In Jellyfin**, go to the book
2. **Three dots (⋮) → Refresh Metadata**
3. **Check "Replace images"**
4. **Click "OK"**

Jellyfin should pick up the cover file automatically.

## Method 3: Batch Add Covers (For Multiple Books)

If you have many books without covers:

1. **Download covers** for all books
2. **Organize them**:
   ```
   /media/books/
   ├── Book 1/
   │   ├── Book 1.epub
   │   └── cover.jpg
   ├── Book 2/
   │   ├── Book 2.epub
   │   └── cover.jpg
   ```

3. **In Jellyfin**: Books library → Three dots (⋮) → **Refresh Metadata**
4. **Check "Replace images"**
5. **Click "OK"**

This will process all books and pick up covers where available.

## Finding Book Covers Online

### Best Sources:
1. **Google Books** - https://books.google.com
   - High quality, official covers
   - Search by title/author

2. **OpenLibrary** - https://openlibrary.org
   - Free, comprehensive
   - Multiple cover sizes available

3. **Amazon** - https://amazon.com
   - Usually has covers for most books
   - Right-click cover image → Save

4. **Goodreads** - https://goodreads.com
   - Community-driven
   - Multiple editions available

## Cover Image Requirements

- **Format**: JPG or PNG
- **Size**: 300x400px minimum (larger is better)
- **Aspect Ratio**: Book cover ratio (taller than wide)
- **File Size**: Under 2MB recommended
- **Naming**: `cover.jpg`, `cover.png`, or `Book Title - cover.jpg`

## Quick Tips

1. **Use Google Image Search**: Search "book title cover" for quick results
2. **Check multiple sources**: Different editions might have better covers
3. **Save in high quality**: Better covers look better in Jellyfin
4. **Organize as you go**: Add covers when you add new books

## Verify Covers Are Working

After adding covers:
1. **Check library view** - covers should appear in grid/list
2. **Check book detail page** - cover should be large and clear
3. **Check mobile app** - covers should sync there too

## Troubleshooting

**Cover not showing after adding file:**
- Make sure file is named `cover.jpg` or `cover.png`
- Refresh metadata for that book
- Check file permissions (should be readable)

**Cover quality is poor:**
- Download higher resolution image
- Jellyfin will resize automatically

**Cover shows but is wrong:**
- Edit metadata in Jellyfin → Images → Replace image
- Or delete the cover file and try different one

## Expected Results

After adding covers manually:
- ✅ Covers appear in library view
- ✅ Covers show in detail pages
- ✅ Covers display in mobile app
- ✅ Covers are cached for performance

Most books should have covers from metadata providers. For the rest, manual addition is quick and easy!


