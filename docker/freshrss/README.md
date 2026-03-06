# FreshRSS

Self-hosted RSS feed aggregator.  
Docs: https://freshrss.org/ | Docker: https://hub.docker.com/r/freshrss/freshrss

## First-time setup

1. From this directory: `docker compose up -d`
2. Open https://rss.gmojsoski.com (after Caddy + tunnel) or http://localhost:8099
3. Complete the web installer: choose language, set admin password, database (default SQLite is fine).

## Port

- **8099** – FreshRSS (used by Caddy reverse proxy).

## URLs

- **Internal:** http://localhost:8099  
- **External:** https://rss.gmojsoski.com  

## Optional

- **Timezone:** Set `TZ` in `.env` (e.g. `Europe/Skopje`).
- **Cron:** `CRON_MIN` controls feed refresh (e.g. `1,31` = every hour at :01 and :31).

## Troubleshooting (unavailable on :8099 or URL)

Run on the **server** (where Docker runs):

1. **Is the container running?**
   ```bash
   docker ps -a | grep freshrss
   ```
   If it’s missing, start it from the compose dir:  
   `cd /path/to/docker/freshrss && docker compose up -d`

2. **If it’s Exited or restarting**, check logs:
   ```bash
   docker logs freshrss
   ```
   Fix any errors (e.g. permission on volumes, bad env).

3. **Is the port bound?**
   ```bash
   sudo ss -tulpn | grep 8099
   ```
   You should see something like `0.0.0.0:8099` and docker-proxy.

4. **Test locally on the server:**
   ```bash
   curl -I http://127.0.0.1:8099/
   ```
   Expect 200 or 302. If “Connection refused”, the container isn’t listening (see logs).

5. **If local works but the URL doesn’t:**  
   Apply config and restart (required after adding a new service):
   ```bash
   cp cloudflare/config.yml ~/.cloudflared/config.yml
   cd docker/caddy && docker compose restart caddy
   cd docker/cloudflared && docker compose restart
   ```
   Then run `./scripts/verify-services.sh`.

6. **Base URL (after first install):**  
   If the site loads but assets/links break behind the proxy, set the base URL in the FreshRSS web UI (Administration → System) to `https://rss.gmojsoski.com`.
