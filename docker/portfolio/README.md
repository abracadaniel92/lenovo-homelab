# Portfolio Service

Ivana's portfolio website running as a containerized Vue.js application.

## Service Details

- **URL**: https://portfolio.gmojsoski.com
- **Port**: 8085
- **Technology**: Vue.js 3 + Vite
- **Container**: Nginx (Alpine)
- **Source**: `/home/goce/Desktop/Cursor projects/ui_portfolio`

## Architecture

The portfolio uses a multi-stage Docker build:

1. **Build Stage**: Node.js 20 Alpine
   - Installs dependencies with `npm ci`
   - Builds the Vue.js app with Vite
   - Outputs static files to `/app/dist`

2. **Production Stage**: Nginx Alpine
   - Serves the built static files
   - Custom nginx configuration for SPA routing
   - Health check endpoint at `/health`

## Configuration

### Nginx Features

- **Gzip Compression**: Enabled for text/css/js files
- **SPA Routing**: Falls back to `index.html` for all routes
- **Static Asset Caching**: 1 year cache for images/fonts
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Health Check**: `/health` endpoint for monitoring

### Resource Limits

- **Memory**: 512MB
- **CPU**: 0.5 cores

## Deployment

### Build and Start

```bash
cd /home/goce/Desktop/Cursor\ projects/Pi-version-control/docker/portfolio
docker compose build
docker compose up -d
```

### Update Portfolio Content

1. Make changes to the source files in `/home/goce/Desktop/Cursor projects/ui_portfolio`
2. Rebuild and restart the container:

```bash
cd /home/goce/Desktop/Cursor\ projects/Pi-version-control/docker/portfolio
docker compose build --no-cache
docker compose up -d
```

### View Logs

```bash
docker logs portfolio -f
```

### Health Check

```bash
# Direct container check
curl http://localhost:8085/health

# Through Caddy
curl -H "Host: portfolio.gmojsoski.com" http://localhost:8080/health

# External access
curl https://portfolio.gmojsoski.com/health
```

## Routing

### Caddy Configuration

Location: `/home/docker-projects/caddy/config/Caddyfile`

```caddyfile
@portfolio host portfolio.gmojsoski.com
handle @portfolio {
    reverse_proxy http://172.17.0.1:8085
}
```

### Cloudflare Tunnel

Location: `~/.cloudflared/config.yml`

```yaml
- hostname: portfolio.gmojsoski.com
  service: http://localhost:8080
```

## Maintenance

### Auto-Updates

Watchtower is enabled for this service. The container will automatically update when a new image is built.

### Manual Restart

```bash
cd /home/goce/Desktop/Cursor\ projects/Pi-version-control/docker/portfolio
docker compose restart
```

### Troubleshooting

1. **Container won't start**: Check logs with `docker logs portfolio`
2. **404 errors**: Verify nginx.conf is properly mounted
3. **External access fails**: 
   - Check Caddy: `curl -H "Host: portfolio.gmojsoski.com" http://localhost:8080`
   - Check Cloudflared: `docker logs cloudflared-cloudflared-1`
   - Run verification: `bash scripts/verify-services.sh`

## Files

- `Dockerfile` - Multi-stage build configuration
- `docker-compose.yml` - Container orchestration
- `nginx.conf` - Nginx web server configuration
- `.dockerignore` - Files to exclude from build context
- `README.md` - This file

## Related Documentation

- [Service Addition Checklist](../../SERVICE_ADDITION_CHECKLIST.md)
- [Main README](../../README.md)
- [Troubleshooting Log](../../usefull%20files/TROUBLESHOOTING_LOG.md)

