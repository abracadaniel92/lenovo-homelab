# Homepage Troubleshooting

## Host Validation Error Fix

If you're seeing "Host validation failed" errors, here's how to fix it:

### Quick Fix

```bash
cd /mnt/ssd/docker-projects/homepage

# Update docker-compose.yml to include environment variable
cat > docker-compose.yml <<EOF
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: always
    ports:
      - "3002:3000"
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - HOMEPAGE_ALLOWED_HOSTS=*
EOF

# Restart container
docker compose down
docker compose up -d
```

### Verify It's Working

```bash
# Check if container is running
docker ps | grep homepage

# Check logs
docker logs homepage --tail 20

# Test access
curl -I http://localhost:3002
# Should return HTTP 200
```

### If Still Not Working

1. **Clear browser cache** - The error might be cached
2. **Try incognito/private window** - To bypass cache
3. **Check if port is correct** - Should be `localhost:3002`
4. **Verify environment variable**:
   ```bash
   docker exec homepage env | grep HOMEPAGE
   ```

### Alternative: Use IP Address

If localhost doesn't work, try:
- `http://127.0.0.1:3002`
- Or your server's IP: `http://YOUR_IP:3002`

### Check Container Status

```bash
# View container status
docker ps -a | grep homepage

# View logs
docker logs homepage --tail 50

# Restart if needed
cd /mnt/ssd/docker-projects/homepage
docker compose restart
```

## Common Issues

### Issue: "Host validation failed"
**Solution**: Set `HOMEPAGE_ALLOWED_HOSTS=*` in docker-compose.yml

### Issue: Can't access from browser
**Solution**: 
- Clear browser cache
- Try incognito mode
- Check firewall rules
- Verify port 3002 is accessible

### Issue: Container keeps restarting
**Solution**: Check logs for errors:
```bash
docker logs homepage --tail 50
```

## Environment Variable Options

```yaml
# Allow all hosts (easiest)
environment:
  - HOMEPAGE_ALLOWED_HOSTS=*

# Allow specific hosts
environment:
  - HOMEPAGE_ALLOWED_HOSTS=localhost:3002,127.0.0.1:3002,localhost,127.0.0.1

# Allow specific domain
environment:
  - HOMEPAGE_ALLOWED_HOSTS=homepage.gmojsoski.com
```

## Still Having Issues?

1. Check Homepage documentation: https://gethomepage.dev/
2. Check GitHub issues: https://github.com/gethomepage/homepage/issues
3. Verify Docker is running: `docker ps`
4. Check system resources: `docker stats homepage`

