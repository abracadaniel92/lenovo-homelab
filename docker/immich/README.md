# Immich

Self-hosted photo and video backup, similar to Google Photos.  
Docs: https://immich.app/docs/install/docker-compose

## Storage

- **Photos/videos:** Currently `./library` (so the server starts reliably). To use the 3TB pool: `sudo mkdir -p /mnt/storage/immich-library`, set `UPLOAD_LOCATION=/mnt/storage/immich-library` in `.env`, then `docker compose up -d --force-recreate immich-server` (Immich will create required subdirs on first run).
- **Database:** `./postgres` (local to this compose; keep on SSD for performance).

## First-time setup

1. **Create postgres dir** if using default: `mkdir -p postgres`

2. **Set a strong DB password** in `.env` (`DB_PASSWORD`). Use only `A-Za-z0-9` (e.g. `pwgen 24`).

3. **Start the stack** (from this directory):
   ```bash
   docker compose up -d
   ```

4. Create an admin user in the web UI, then install the mobile app and log in.

## URLs

- **Internal:** http://localhost:2283  
- **External (after Caddy + tunnel):** https://immich.gmojsoski.com  

## Port

- **2283** – Immich server (used by Caddy reverse proxy).
