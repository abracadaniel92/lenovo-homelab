# Service Addition Checklist (Gold Standard)

Follow this checklist whenever adding a new service to the homelab. This ensures stability and prevents the "Service Down" issues we've experienced.

## 1. Docker Compose Configuration
- [ ] **Network Mode**: Unless absolutely necessary, DO NOT use `network_mode: host`. Use standard bridge networks.
- [ ] **Port Conflicts**: Check if the port is already in use (`sudo ss -tulpn | grep :<PORT>`).
- [ ] **Data Persistence**: Ensure volumes are mapped to `/mnt/ssd/docker-projects/<service>/data` (or similar) to avoid data loss.
- [ ] **Restart Policy**: Always set `restart: unless-stopped`.

## 2. Caddy Configuration (`docker/caddy/Caddyfile`)
- [ ] **Standard Proxy Block**: Use the standard template. Do NOT add `header_up Host {host}` unless the specific application documentation explicitly demands it for a reverse proxy.
    ```caddyfile
    @service_name host service.gmojsoski.com
    handle @service_name {
        reverse_proxy http://172.17.0.1:PORT
    }
    ```
- [ ] **Avoid Gzip for Media**: For media servers (Jellyfin, Plex), explicitly DISABLE gzip if mobile clients have issues.
- [ ] **SSL Headers**: If the app runs behind a proxy and expects HTTPS signals, add:
    ```caddyfile
    header_up X-Forwarded-Proto https
    header_up X-Forwarded-Ssl on
    ```
- [ ] **Validation**: Run `docker exec caddy caddy validate --config /etc/caddy/Caddyfile` BEFORE restarting.

## 3. Cloudflare Tunnel Configuration (`~/.cloudflared/config.yml`)
- [ ] **Localhost Binding**: ALWAYS use `localhost:8080` for the service URL, NOT `127.0.0.1`.
    ```yaml
    - hostname: service.gmojsoski.com
      service: http://localhost:8080
    ```
- [ ] **Ingress Rule**: Add the new hostname to the ingress list.
- [ ] **Integrity**: Ensure no other rules have been modified.

## 4. Verification (The "Triple Check")
- [ ] **Internal Check**: `curl -I http://localhost:PORT` (from the host).
- [ ] **Internal Proxy Check**: `curl -H "Host: service.gmojsoski.com" http://localhost:8080` (verifies Caddy).
- [ ] **External Check**: `curl -I https://service.gmojsoski.com` (verifies Cloudflare).
- [ ] **Mobile Check**: disable Wi-Fi on phone and check if site loads.

## 5. Updates
- [ ] **Scripts**: Update `scripts/verify-services.sh` to include the new domain.
- [ ] **Documentation**: Update `README.md` with the new service details and port number.

## ❓ Operational Procedures & FAQ

### 1. Restart Sequence
**Order Matters:**
1.  **Restart Caddy First**: `docker compose restart caddy` (loads new internal routing).
2.  **Restart Tunnel Second**: `docker compose restart` in the cloudflared folder (registers new ingress rule).
*Why?* The tunnel needs to see the internal route is ready.

### 2. Verification
**Mandatory**: YES. Always run `./scripts/verify-services.sh` after any change. This is your safety net.

### 3. Logging
**Troubleshooting Log**: Only log here if you encountered *problems* or had to do non-standard fix.
**Standard Additions**: No need to log smooth additions in TROUBLESHOOTING_LOG.md. Just update `README.md`.

### 4. Port Allocation
**Preferred Range**: 8000-8100 is your current active range.
*   **Procedure**: Always run `sudo ss -tulpn` first.
*   **Avoid**: 5000 (AirPlay conflict), 9000 (Portainer).

### 5. Rollback Procedure
If a new service breaks things:
1.  **Revert**: Delete the lines you added to `Caddyfile` and `config.yml`.
2.  **Reset**: Run `docker compose restart caddy`.
3.  **Recover**: Run `./restart services/fix-external-access.sh` (this resets the tunnel cleanly).
4.  **Verify**: Run `./scripts/verify-services.sh` to confirm you are back to green.
