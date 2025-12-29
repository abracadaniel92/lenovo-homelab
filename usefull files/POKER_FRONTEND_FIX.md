# Poker Frontend Fix

**Date**: December 28, 2025

## Issue

Poker service was accessible but frontend (CSS/JS) wasn't loading when accessed via public URL (https://poker.gmojsoski.com).

## Root Cause

The Caddy reverse proxy configuration for poker was missing the `Host` header forwarding. When static assets (style.css, app.js) were requested, Caddy wasn't properly forwarding the Host header to the Express server, causing routing issues.

## Fix Applied

Updated the Caddyfile poker route to include proper header forwarding:

```caddy
@poker host poker.gmojsoski.com
handle @poker {
    encode gzip
    reverse_proxy http://172.17.0.1:3000 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
        header_up Host {host}              # Added
        header_up X-Forwarded-Host {host}  # Added
    }
}
```

## Verification

After the fix:
- ✅ HTML loads correctly
- ✅ CSS (style.css) loads correctly (HTTP 200)
- ✅ JavaScript (app.js) loads correctly (HTTP 200)
- ✅ All static assets properly proxied

## Status

✅ **Fixed** - Poker frontend now loads completely when accessed via https://poker.gmojsoski.com

