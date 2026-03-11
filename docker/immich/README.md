# Immich

Self-hosted photo and video backup, similar to Google Photos.  
Docs: https://immich.app/docs/install/docker-compose

## Storage (this instance)

- **Photos/videos (primary):** `/mnt/ssd_1tb/immich-library` on the **1TB SATA SSD** (primary, healthiest drive). Set in `.env`: `UPLOAD_LOCATION=/mnt/ssd_1tb/immich-library`. To migrate from the old mergerfs location, run from repo root: `sudo bash scripts/migrate-immich-to-ssd1tb.sh`.
- **Database:** `./postgres` (local to this compose; keep on fast storage for performance).

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

## Security (this instance)

- **OAuth (Google):** Auto Register **disabled** — only admin-created users can log in with Google.
- **Password login:** **Disabled** in Administration → Settings — prevents guessing; access is OAuth-only.
- Add users via Administration → Users; they link Google in User settings → OAuth after first sign-in.

## Troubleshooting

- **Crash on start (encoded-video/.immich ENOENT):** Empty library lacks subdirs. Use `IMMICH_IGNORE_MOUNT_CHECK_ERRORS=true` in `.env`, or run `sudo docker/immich/create-library-dirs.sh /mnt/ssd_1tb/immich-library`. See `usefull files/TROUBLESHOOTING_LOG.md`.
