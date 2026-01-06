# Service Addition Checklist

Follow this checklist whenever adding a new service to the homelab.

## 1. Docker Compose Configuration
- [ ] **Network Mode**: Unless absolutely necessary, DO NOT use `network_mode: host`
- [ ] **Port Conflicts**: Check if the port is already in use (`sudo ss -tulpn | grep :<PORT>`)
- [ ] **Data Persistence**: Ensure volumes are mapped correctly
- [ ] **Restart Policy**: Always set `restart: unless-stopped`

## 2. Caddy Configuration
- [ ] **Standard Proxy Block**: Use the standard template
- [ ] **Avoid Gzip for Media**: For media servers, explicitly DISABLE gzip if mobile clients have issues
- [ ] **Validation**: Run `docker exec caddy caddy validate --config /etc/caddy/Caddyfile` BEFORE restarting

## 3. Cloudflare Tunnel Configuration
- [ ] **Localhost Binding**: ALWAYS use `localhost:8080` for the service URL, NOT `127.0.0.1`
- [ ] **Ingress Rule**: Add the new hostname to the ingress list
- [ ] **Integrity**: Ensure no other rules have been modified

## 4. Verification (The "Triple Check")
- [ ] **Internal Check**: `curl -I http://localhost:PORT`
- [ ] **Internal Proxy Check**: `curl -H "Host: service.gmojsoski.com" http://localhost:8080`
- [ ] **External Check**: `curl -I https://service.gmojsoski.com`
- [ ] **Mobile Check**: disable Wi-Fi on phone and check if site loads

## 5. Updates
- [ ] **Scripts**: Update `scripts/verify-services.sh` to include the new domain
- [ ] **Documentation**: Update `README.md` with the new service details

## Restart Sequence
1. **Restart Caddy First**: `docker compose restart caddy`
2. **Restart Tunnel Second**: `docker compose restart` in the cloudflared folder

## Rollback Procedure
If a new service breaks things:
1. **Revert**: Delete the lines you added to `Caddyfile` and `config.yml`
2. **Reset**: Run `docker compose restart caddy`
3. **Recover**: Run `./restart services/fix-external-access.sh`
4. **Verify**: Run `./scripts/verify-services.sh`

