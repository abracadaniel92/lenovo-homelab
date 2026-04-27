# Stirling PDF (Local Only)

Stirling PDF is deployed as a local-only Docker service (no Cloudflare subdomain).

## Access

- Login page (on server): `http://localhost:8095/login`
- Login page (LAN devices): `http://<server-ip>:8095/login`

## Storage

Persistent data is stored on the internal 1TB SSD at:

- `/mnt/ssd_1tb/stirling-pdf/config`
- `/mnt/ssd_1tb/stirling-pdf/trainingData`
- `/mnt/ssd_1tb/stirling-pdf/customFiles`
- `/mnt/ssd_1tb/stirling-pdf/logs`
- `/mnt/ssd_1tb/stirling-pdf/pipeline`

## Manage

```bash
cd /home/goce/Desktop/Cursor\ projects/Pi-version-control/docker/stirling-pdf
docker compose up -d
docker compose logs -f
docker compose down
```
