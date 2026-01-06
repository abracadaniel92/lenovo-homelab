# Outline Wiki Setup

Outline is a modern, fast wiki and knowledge base for teams.

## 🔧 Configuration

- **Port**: 8098 (internal only)
- **Access**: http://outline.local:8080 (via Caddy)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Storage**: Local filesystem

## 🚀 First-Time Setup

### 1. Generate Secret Keys

Before starting, replace the placeholder secrets in `docker-compose.yml`:

```bash
# Generate SECRET_KEY (32+ characters)
openssl rand -hex 32

# Generate UTILS_SECRET (32+ characters)
openssl rand -hex 32
```

Update these values in the `docker-compose.yml` file.

### 2. Start Services

```bash
cd /home/goce/Desktop/Cursor\ projects/Pi-version-control/docker/outline
docker compose up -d
```

### 3. Check Status

```bash
docker compose ps
docker compose logs -f outline
```

### 4. Create Admin User

After services are running, create your first admin user:

```bash
docker exec -it outline yarn db:create-admin --email your@email.com --name "Your Name"
```

This will output a temporary password. Use it to log in, then change it immediately.

## 📝 Usage

Access Outline at: **http://outline.local:8080** (or http://localhost:8098 directly)

## 🔄 Maintenance

### View Logs
```bash
cd /home/goce/Desktop/Cursor\ projects/Pi-version-control/docker/outline
docker compose logs -f outline
```

### Restart Service
```bash
docker compose restart outline
```

### Update Outline
```bash
docker compose pull
docker compose up -d
```

### Backup Database
```bash
docker exec outline-postgres pg_dump -U outline outline > outline-backup-$(date +%Y%m%d).sql
```

### Restore Database
```bash
cat outline-backup-YYYYMMDD.sql | docker exec -i outline-postgres psql -U outline outline
```

## 🐛 Troubleshooting

### Service won't start
```bash
# Check logs
docker compose logs outline

# Verify database is ready
docker compose logs outline-postgres

# Check Redis
docker exec outline-redis redis-cli ping
```

### Reset admin password
```bash
docker exec -it outline yarn db:reset-password --email your@email.com
```

## 🔐 Security Notes

1. **Change default secrets** in docker-compose.yml before first run
2. **Keep internal only** - this is not exposed via Cloudflare tunnel
3. **Regular backups** - database contains all your documentation
4. Consider setting `POSTGRES_PASSWORD` to something stronger

## 📚 Links

- [Outline Documentation](https://docs.getoutline.com/)
- [Outline GitHub](https://github.com/outline/outline)
- [Self-Hosting Guide](https://docs.getoutline.com/s/hosting/)

