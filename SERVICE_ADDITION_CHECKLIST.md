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
