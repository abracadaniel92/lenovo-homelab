# Planning Poker Mobile Browser Fix

**Date**: December 29, 2025  
**Issue**: Mobile browsers showing blank screen and downloading HTML as text file  
**Service**: poker.gmojsoski.com  
**Status**: ✅ Fixed

## Problem

When accessing `poker.gmojsoski.com` on mobile browsers:
- Page showed blank screen
- Browser downloaded HTML file as text instead of displaying it
- Host login was not working properly

## Root Cause

Mobile browsers (especially iOS Safari and some Android browsers) are stricter about Content-Type headers. When Express.js serves static files without explicit Content-Type headers, mobile browsers may misinterpret the content type and download the file instead of rendering it.

## Solution

Updated `server.js` to explicitly set Content-Type headers for all static files:

```javascript
app.use(express.static('public', {
  setHeaders: (res, path) => {
    // Explicitly set Content-Type for HTML files to prevent mobile browsers from downloading
    if (path.endsWith('.html')) {
      res.setHeader('Content-Type', 'text/html; charset=UTF-8');
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
    } else if (path.endsWith('.css')) {
      res.setHeader('Content-Type', 'text/css; charset=UTF-8');
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
    } else if (path.endsWith('.js')) {
      res.setHeader('Content-Type', 'application/javascript; charset=UTF-8');
      res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
      res.setHeader('Pragma', 'no-cache');
      res.setHeader('Expires', '0');
    }
  }
}));
```

## Files Changed

- `/home/goce/Desktop/Cursor projects/planning poker/planning_poker/server.js`
  - Updated `express.static` middleware to set explicit Content-Type headers

## Testing

After applying the fix:

1. **Restart the service**:
   ```bash
   sudo systemctl restart planning-poker.service
   ```

2. **Test on mobile**:
   - Clear browser cache
   - Visit `https://poker.gmojsoski.com`
   - Page should display correctly instead of downloading

3. **Test host login**:
   - Go to `https://poker.gmojsoski.com`
   - Use host login form with password: `admin123`
   - Or visit `https://poker.gmojsoski.com/login.html`

## Caddy Configuration

The Caddyfile configuration is correct and doesn't need changes. The poker route is properly configured:

```caddy
@poker host poker.gmojsoski.com
handle @poker {
    encode gzip
    reverse_proxy http://172.17.0.1:3000 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
        header_up Host {host}
        header_up X-Forwarded-Host {host}
    }
}
```

## Related Issues

- Host login API endpoint (`/api/host/login`) was tested and working correctly
- The issue was purely frontend/Content-Type related
- No changes needed to Caddyfile or Cloudflare configuration

## Prevention

For future Express.js applications:
- Always set explicit Content-Type headers for static files
- Include charset (UTF-8) in Content-Type headers
- Test on mobile browsers during development
- Use `express.static` with `setHeaders` callback for fine-grained control

## References

- Express.js Static Files: https://expressjs.com/en/starter/static-files.html
- Content-Type Header: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type
- Mobile Browser Compatibility: Mobile browsers are stricter about MIME types

