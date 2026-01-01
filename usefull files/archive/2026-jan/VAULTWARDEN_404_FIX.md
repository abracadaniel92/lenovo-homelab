# Vaultwarden 404/400 Error Fix

## Problem
Bitwarden mobile app was returning `BitwardenKit.ResponseValidationError` with `statusCode: 404` or `400 Bad Request` when trying to access Vaultwarden.

## Root Causes

### Issue 1: Missing Route
The `vault.gmojsoski.com` route was **completely missing** from the deployed Caddyfile at `/mnt/ssd/docker-projects/caddy/config/Caddyfile`.

### Issue 2: Gzip Encoding Breaking Rocket (400 Bad Request)
Vaultwarden uses the Rocket web framework which **does NOT handle gzip-compressed requests** properly when forwarded through Caddy. Adding `encode gzip` to the vault block causes Rocket to return "Bad incoming HTTP request" errors.

## Symptoms
- External access to `https://vault.gmojsoski.com` returned 200 (main page worked)
- `/identity/connect/token` endpoint returned 404
- Bitwarden mobile app couldn't authenticate
- Requests to `/identity/connect/token` were not appearing in Vaultwarden logs (indicating Caddy was rejecting them before proxying)

## Solution

### 1. Fixed the Deployed Caddyfile
The Caddyfile at `/mnt/ssd/docker-projects/caddy/config/Caddyfile` needed the vault route added **WITHOUT gzip encoding**:

```caddy
@vault host vault.gmojsoski.com
handle @vault {
	# NO gzip encoding - Rocket/Vaultwarden doesn't handle it well
	reverse_proxy http://172.17.0.1:8082 {
		header_up X-Forwarded-Proto https
		header_up X-Real-IP {remote_host}
	}
}
```

**CRITICAL:** Do NOT add `encode gzip` to the vault block - this causes 400 errors!

### 2. Important Notes About Caddyfile Syntax
- **Correct syntax**: Use `@matcher host domain.com` pattern inside `:80` block
- **Incorrect syntax**: Don't use `domain.com { }` blocks directly inside `:80` block
- The Caddyfile must be in `/mnt/ssd/docker-projects/caddy/config/Caddyfile` (not `/mnt/ssd/docker-projects/caddy/Caddyfile`)

### 3. Restart Caddy
After updating the Caddyfile:
```bash
docker compose -f /mnt/ssd/docker-projects/caddy/docker-compose.yml restart caddy
```

### 4. Verify Fix
Test the endpoint:
```bash
curl -s -o /dev/null -w "%{http_code}" https://vault.gmojsoski.com/identity/connect/token -X POST -H "Content-Type: application/x-www-form-urlencoded"
```
- **Before fix**: 404 (Not Found)
- **After fix**: 422 (Unprocessable Entity) - This is expected! It means the request reached Vaultwarden, but we're not sending valid auth parameters. The important thing is it's no longer 404.

## Prevention

### 1. Keep Repository and Deployed Caddyfile in Sync
Always update both:
- Repository: `/home/goce/Desktop/Cursor projects/Pi-version-control/docker/caddy/Caddyfile`
- Deployed: `/mnt/ssd/docker-projects/caddy/config/Caddyfile`

### 2. Verify Caddyfile Location
Check where Caddy is actually reading from:
```bash
docker inspect caddy | grep -A 20 "Mounts"
```
The Caddyfile should be mounted at `/etc/caddy/Caddyfile` inside the container.

### 3. Test After Changes
After updating the Caddyfile:
1. Check Caddy logs: `docker logs caddy --tail 20`
2. Verify no syntax errors
3. Test the endpoint: `curl -I https://vault.gmojsoski.com`

### 4. Quick Fix Script
If vault route is missing again:
```bash
# Copy from repository to deployed location
cp "/home/goce/Desktop/Cursor projects/Pi-version-control/docker/caddy/Caddyfile" /mnt/ssd/docker-projects/caddy/config/Caddyfile

# Restart Caddy
docker compose -f /mnt/ssd/docker-projects/caddy/docker-compose.yml restart caddy

# Verify
docker logs caddy --tail 10
```

---

## Additional Fix: DELETE Method for Cipher Deletion

### Problem
Bitwarden mobile app sends `DELETE` requests to `/api/ciphers/{id}/delete`, but Vaultwarden's API expects `PUT` requests. This caused 404 errors when trying to delete items.

### Solution: Nginx Proxy for Method Rewriting
Caddy cannot reliably rewrite HTTP methods for Vaultwarden (breaks Rocket). Instead, we use Nginx as an intermediate proxy:

**Architecture:**
```
Cloudflare → Caddy (8080) → Nginx (8083) → Vaultwarden (8082)
```

**Nginx config** (`/mnt/ssd/docker-projects/nginx-vaultwarden/nginx.conf`):
- Rewrites DELETE to PUT for `/api/ciphers/*/delete` endpoints
- Passes all other requests through normally

**Caddy routes vault.gmojsoski.com to Nginx (port 8083):**
```caddy
@vault host vault.gmojsoski.com
handle @vault {
	reverse_proxy http://172.17.0.1:8083 {
		header_up X-Forwarded-Proto https
		header_up X-Real-IP {remote_host}
	}
}
```

### Starting the Nginx Proxy
```bash
cd /mnt/ssd/docker-projects/nginx-vaultwarden
docker compose up -d
```

### Verification
- **Before fix**: `DELETE /api/ciphers/{id}/delete` → 404 Not Found
- **After fix**: `DELETE /api/ciphers/{id}/delete` → Nginx rewrites to PUT → 401 (expected without valid auth)

### Date Fixed
2025-12-31

---

## Date Fixed
2025-12-31

## Related Files
- `/mnt/ssd/docker-projects/caddy/config/Caddyfile` - Deployed Caddyfile
- `/home/goce/Desktop/Cursor projects/Pi-version-control/docker/caddy/Caddyfile` - Repository Caddyfile
- `/mnt/ssd/docker-projects/vaultwarden/docker-compose.yml` - Vaultwarden configuration

