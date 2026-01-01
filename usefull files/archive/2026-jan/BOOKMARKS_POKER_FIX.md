# Fix Bookmarks and Poker Services

## Issues Found

### 1. Bookmarks (bookmarks.gmojsoski.com)
- **Status**: Service is running but returning 404
- **Problem**: Flask app doesn't have a route for `/` or needs restart
- **Fix**: Restart service and check Flask routes

### 2. Poker (poker.gmojsoski.com)
- **Status**: Service is NOT running
- **Problem**: Planning poker app is not started
- **Fix**: Start the service

## Fixes

### Fix Bookmarks

1. **Restart the service**:
   ```bash
   sudo systemctl restart bookmarks.service
   ```

2. **Check if it's working**:
   ```bash
   curl http://localhost:5000/
   ```

3. **If still 404, check Flask routes**:
   - The Flask app might need a specific path (like `/api` or `/bookmarks`)
   - Check the Flask app code to see what routes are defined
   - Update Caddy config if needed to proxy to the correct path

4. **Check service logs**:
   ```bash
   journalctl -u bookmarks.service -f
   ```

### Fix Poker

1. **Start Planning Poker**:
   ```bash
   cd '/home/goce/Desktop/Cursor projects/planning poker/planning_poker'
   
   # Option 1: Using PM2 (if installed)
   pm2 start ecosystem.config.js
   pm2 save
   
   # Option 2: Using Node directly (runs in foreground)
   node server.js
   
   # Option 3: Create systemd service (recommended for auto-start)
   ```

2. **Create systemd service for auto-start** (Recommended):
   ```bash
   sudo nano /etc/systemd/system/planning-poker.service
   ```
   
   Add:
   ```ini
   [Unit]
   Description=Planning Poker Service
   After=network.target
   
   [Service]
   Type=simple
   User=goce
   WorkingDirectory=/home/goce/Desktop/Cursor projects/planning poker/planning_poker
   ExecStart=/usr/bin/node server.js
   Restart=always
   RestartSec=10
   Environment="PORT=3000"
   Environment="HOST_PASSWORD=admin123"
   
   [Install]
   WantedBy=multi-user.target
   ```
   
   Then:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable planning-poker.service
   sudo systemctl start planning-poker.service
   ```

3. **Verify it's running**:
   ```bash
   curl http://localhost:3000
   systemctl status planning-poker.service
   ```

4. **Check Caddy config**:
   - Verify Caddy has route for `poker.gmojsoski.com`
   - If missing, add it (see below)
   - Reload Caddy: `docker exec caddy caddy reload`

## Caddy Configuration

If poker route is missing in Caddy, add this to Caddyfile:

```
@poker host poker.gmojsoski.com
handle @poker {
    encode gzip
    reverse_proxy http://172.17.0.1:3000 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
    }
}
```

Then reload Caddy:
```bash
docker exec caddy caddy reload
```

## Verification

After fixes, test:

```bash
# Bookmarks
curl -I https://bookmarks.gmojsoski.com

# Poker
curl -I https://poker.gmojsoski.com
```

Both should return `HTTP/2 200` instead of 404/502.

