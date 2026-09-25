# Scrutiny — SMART disk health dashboard

Web UI + collector (omnibus image) for disk health trends and failure
prediction. Complements `scripts/hdd-health-check.sh` with history and a UI.

- **Port**: `8084` (LAN only — do NOT add a Caddy/tunnel route)
- **Data**: `./config` + `./influxdb` (small, lives with the stack dir)
- **Collector**: built into the omnibus image, runs every ~15 min

Setup, verification, and integration steps:
[docs/how-to-guides/add-monitoring-trio.md](../../docs/how-to-guides/add-monitoring-trio.md)
