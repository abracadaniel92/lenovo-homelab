# Nginx Proxy for Vaultwarden

This Nginx container acts as an intermediate proxy between Caddy and Vaultwarden to handle HTTP method rewriting.

## Why is this needed?

1. **DELETE to PUT rewrite**: The Bitwarden iOS app sends `DELETE` requests to `/api/ciphers/{id}/delete`, but Vaultwarden expects `PUT` requests. Nginx rewrites the method.

2. **Rocket framework compatibility**: Vaultwarden uses the Rocket web framework which doesn't handle certain request modifications from Caddy well (like `encode gzip` or complex rewrites).

## Architecture

```
Internet → Cloudflare → Caddy (8080) → Nginx (8083) → Vaultwarden (8082)
```

## Deployment

```bash
cd /mnt/ssd/docker-projects/nginx-vaultwarden
docker compose up -d
```

## Configuration

### Nginx (`nginx.conf`)
- Listens on port 80 (mapped to host 8083)
- Rewrites DELETE to PUT for cipher delete endpoints
- Proxies all requests to Vaultwarden (172.17.0.1:8082)

### Caddy
Update Caddyfile to route `vault.gmojsoski.com` to port 8083:
```caddy
@vault host vault.gmojsoski.com
handle @vault {
    reverse_proxy http://172.17.0.1:8083 {
        header_up X-Forwarded-Proto https
        header_up X-Real-IP {remote_host}
    }
}
```

## Troubleshooting

### Check if Nginx is running
```bash
docker ps | grep nginx-vaultwarden
```

### Check logs
```bash
docker logs nginx-vaultwarden
```

### Test DELETE rewrite
```bash
# This should return 401 (not 404)
curl -X DELETE http://localhost:8083/api/ciphers/test-id/delete -H "Authorization: Bearer test"
```

### Check Vaultwarden logs for method
```bash
docker logs vaultwarden --tail 10
# Should show: PUT /api/ciphers/<cipher_id>/delete
```

