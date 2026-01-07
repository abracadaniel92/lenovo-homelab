# Paperless-ngx Setup

Document management system for digitizing and organizing physical documents.

## Configuration

- **Port**: 8097
- **External URL**: https://paperless.gmojsoski.com
- **Database**: Shared PostgreSQL (Nextcloud instance)
- **Database Name**: `paperless` (separate from Nextcloud's database)

## Initial Setup

### 1. Create Environment File

Copy the example environment file and configure it:

```bash
cd /home/docker-projects/paperless
cp .env.example .env
```

### 2. Generate Secret Key

Generate a strong secret key for Paperless:

```bash
openssl rand -base64 32
```

Add this to your `.env` file as `PAPERLESS_SECRET_KEY=...`

### 3. Create Database

Before starting Paperless, create the database on the shared PostgreSQL instance:

```bash
docker exec -it nextcloud-postgres psql -U nextcloud -d postgres -c "CREATE DATABASE paperless;"
```

### 4. Start Paperless

```bash
cd /home/docker-projects/paperless
docker compose pull
docker compose up -d
```

### 5. Create Admin User

After the container starts, create an admin user:

```bash
docker exec -it paperless-webserver python manage.py createsuperuser
```

## Directory Structure

```
/home/docker-projects/paperless/
├── docker-compose.yml
├── .env                    # Environment variables (gitignored)
├── .env.example           # Template
├── consume/               # Drop documents here for automatic processing
├── export/                # Exported documents
└── README.md
```

## Volumes

- `data`: Paperless application data
- `media`: Processed documents and media files
- `redisdata`: Redis cache data

## Access

- **Local**: http://localhost:8097
- **External**: https://paperless.gmojsoski.com (via Caddy reverse proxy)

## Maintenance

### Update Paperless

```bash
cd /home/docker-projects/paperless
docker compose pull
docker compose up -d
```

### View Logs

```bash
docker compose logs -f webserver
```

### Backup

Paperless data is stored in Docker volumes. To backup:

```bash
# Backup volumes
docker run --rm -v paperless_data:/data -v $(pwd):/backup alpine tar czf /backup/paperless-data-backup.tar.gz /data
docker run --rm -v paperless_media:/data -v $(pwd):/backup alpine tar czf /backup/paperless-media-backup.tar.gz /data
```

### Restore

```bash
# Restore volumes
docker run --rm -v paperless_data:/data -v $(pwd):/backup alpine tar xzf /backup/paperless-data-backup.tar.gz -C /
docker run --rm -v paperless_media:/data -v $(pwd):/backup alpine tar xzf /backup/paperless-media-backup.tar.gz -C /
```

## Notes

- Paperless uses the shared Nextcloud PostgreSQL container (`nextcloud-postgres`)
- The database is separate from Nextcloud's database
- Redis is used for task queue and caching
- Documents dropped in `./consume/` are automatically processed
- Exported documents are saved to `./export/`

## Reference

- [Paperless-ngx Documentation](https://docs.paperless-ngx.com/)
- Fork: `/home/goce/Desktop/Cursor projects/paperless-ngx`



