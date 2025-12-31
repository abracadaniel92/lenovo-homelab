# Creating Books Library in Jellyfin - Step by Step

## The Form Structure

When you click "Add Media Library", you should see a form with these sections **IN ORDER**:

### 1. **Content Type** (AT THE TOP - Most Important!)
- **Location**: Very top of the form
- **What it looks like**: A dropdown menu
- **Options**: Movies, TV Shows, Music, **Books**, Mixed Content, etc.
- **ACTION**: **MUST select "Books"** from this dropdown
- **Why**: Only "Books" type shows book metadata options

### 2. **Display Name**
- Text field
- Enter: "Books"

### 3. **Folders**
- Click the **"+"** button
- Browse to: `/media/books`
- Or manually enter the path

### 4. **Library Settings** (What you're seeing)
- Enable the library
- Enable real time monitoring

### 5. **Metadata** (Scroll down - appears AFTER selecting "Books")
- Only visible when Content Type = "Books"
- Metadata providers section
- OpenLibrary, Google Books options
- "Download images in advance" checkbox

## If You Don't See "Content Type" Dropdown

### Try This:
1. **Scroll to the very top** of the form
2. **Look for a dropdown** that might say "Content Type" or "Type"
3. **Check if there are tabs** at the top of the form
4. **Try clicking "Cancel" and starting over**
5. **Refresh the page** and try again

### Alternative: Check Existing Libraries

If you already have libraries:
1. **Dashboard → Libraries**
2. **Click the pencil/edit icon** on any library
3. **Look at the top** - do you see "Content Type" there?
4. If yes, note where it is and use that location when creating new library

## Quick Checklist

When creating Books library:
- [ ] See "Content Type" dropdown at top
- [ ] Selected "Books" from dropdown
- [ ] Added folder: `/media/books`
- [ ] Scrolled down to see "Metadata" section
- [ ] Enabled OpenLibrary and Google Books
- [ ] Checked "Download images in advance"
- [ ] Clicked "OK" or "Save"

## Still Can't Find It?

**Option 1: Edit Existing Library**
- If you have a library that already has books
- Edit it and change Content Type to "Books"
- This might be easier than creating new

**Option 2: Check Jellyfin Version**
- Older versions might have different UI
- Try updating Jellyfin: `docker pull jellyfin/jellyfin:latest && docker restart jellyfin`

**Option 3: Screenshot**
- Take a screenshot of the "Add Media Library" form
- This will help identify what's missing

## Expected Result

After selecting "Books" as Content Type and scrolling down, you should see:

```
Metadata
├── Metadata downloaders
│   ├── [ ] OpenLibrary
│   ├── [ ] Google Books
│   └── [ ] Audible
├── Image fetchers
│   └── (various options)
└── [✓] Download images in advance
```

If you don't see this after selecting "Books", there might be a UI issue or the Bookshelf plugin needs to be restarted.

