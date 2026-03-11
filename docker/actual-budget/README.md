# Actual Budget

Personal finance and budgeting app (self-hosted).  
Docs: https://actualbudget.org/docs/install/docker/

## Storage

- **Data:** `/home/actual-budget` (NVMe /home partition).
- The server creates `server-files` and `user-files` under that path.

## URLs

- **Internal:** http://localhost:5006  
- **External:** https://budget.gmojsoski.com  

## Port

**5006** – Actual server (Caddy reverse proxy).

## First run

1. Ensure the data directory exists: `mkdir -p /home/actual-budget` (or `sudo mkdir -p /home/actual-budget` if needed)
2. From this directory: `docker compose up -d`
3. Open https://budget.gmojsoski.com (or http://localhost:5006), create a user and budget.

## Update

```bash
docker compose pull && docker compose up -d
```
