# ntfy — self-hosted push notifications

Phone/desktop push for health checks, backups, Uptime Kuma, and Watchtower.
Public at `ntfy.gmojsoski.com` (needed for push to phones off-LAN), locked
down with `deny-all` auth + explicit users.

- **Port**: `8085` (host) → `80` (container)
- **Public route**: yes — Caddy `50-utilities.caddy` + tunnel hostname
- **Data**: `./cache` + `./lib` (message cache + auth db, small)

After first start, create the admin user **on the server**:

```bash
docker exec -it ntfy ntfy user add --role=admin goce
```

Setup, verification, and integration steps:
[docs/how-to-guides/add-monitoring-trio.md](../../docs/how-to-guides/add-monitoring-trio.md)
