# Beszel — lightweight resource metrics

CPU / RAM / disk / temperature / per-container history for lemongrab (and
optionally the Pi later via a second agent). Fills the gap between "is it up?"
(Uptime Kuma) and "why was it slow last Tuesday?".

- **Ports**: `8086` hub web UI (LAN only); agent listens on `45876`
  (host network — record it in the port map)
- **Data**: `./beszel_data` (small)
- **First run order**: start the hub → open UI → add system
  (`host IP`, port `45876`) → copy the public key into the agent's `KEY`
  env → `docker compose up -d` again to restart the agent

Setup, verification, and integration steps:
[docs/how-to-guides/add-monitoring-trio.md](../../docs/how-to-guides/add-monitoring-trio.md)
