# Add the monitoring trio: Scrutiny, ntfy, Beszel

Walkthrough for deploying three complementary monitoring services, following
[SERVICE_ADDITION_CHECKLIST.md](../../SERVICE_ADDITION_CHECKLIST.md).
Compose files are already prepared in the repo under `docker/scrutiny/`,
`docker/ntfy/`, and `docker/beszel/`.

> **Status: deployed on lemongrab (2026-07-28).** Remaining manual step:
> add Beszel system in hub UI (`http://192.168.1.97:8086`) → paste token
> into `docker/beszel/docker-compose.yml` → `docker compose up -d`.
> Optional: wire Uptime Kuma monitors and ntfy notification topics.

| Service | Host port | Exposure | What it adds |
|---|---|---|---|
| Scrutiny | 8084 | **LAN only** | SMART disk-health history + failure prediction UI |
| ntfy | 8085 | **Public** — `ntfy.gmojsoski.com` | Push notifications to phone from all monitoring |
| Beszel | 8086 (hub) + 45876 (agent) | **LAN only** | CPU/RAM/disk/temp/per-container metrics history |

Storage note (governance rule 10/11): all three keep small data (`./…` dirs
next to the compose file, i.e. on `/home`, NVMe). Nothing goes on `/` or the
mergerfs array. If you'd rather have the Beszel/Scrutiny time-series DBs on
`/mnt/ssd_1tb`, change the volume paths before first start — moving later
means losing history or a manual copy.

## 0. Preconditions (once, on lemongrab)

```bash
cd ~/Pi-version-control && git pull            # get the prepared compose files
sudo ss -tulpn | grep -E ':8084|:8085|:8086|:45876'   # must all be free
lsblk -d -o NAME,MODEL,SIZE                    # disk list for Scrutiny devices
```

If any port is taken, pick another free one from
[port-map.md](../reference/port-map.md) and adjust the compose file +
every snippet below.

---

## 1. Scrutiny (LAN only — no Caddy, no tunnel)

1. Edit `docker/scrutiny/docker-compose.yml` → `devices:` list to match
   `lsblk` output (every physical disk, including the mergerfs members and
   the old 500GB — that's the one you most want watched).
2. Start it:
   ```bash
   cd ~/Pi-version-control/docker/scrutiny && docker compose up -d
   ```
3. Verify:
   ```bash
   curl -I http://localhost:8084          # expect 200
   docker logs scrutiny --tail 20         # collector should list all disks
   ```
   Open `http://192.168.1.97:8084` — every disk appears with SMART data
   (first collection can take a few minutes; collector re-runs ~15 min).
4. Optional: in Scrutiny **Settings → Notifications**, add the ntfy endpoint
   from step 2 (`https://ntfy.gmojsoski.com/disk-alerts`) so failing SMART
   attributes push to your phone.

**Rollback**: `docker compose down` in the same dir. Nothing else references it.

---

## 2. ntfy (public — full checklist applies)

### 2a. Start the container

```bash
cd ~/Pi-version-control/docker/ntfy && docker compose up -d
docker exec -it ntfy ntfy user add --role=admin goce     # set password when prompted
curl -I http://localhost:8085     # expect 200 (or 401 on some paths — fine)
```

### 2b. Caddy route (append to `docker/caddy/config.d/50-utilities.caddy`)

```caddyfile
@ntfy host ntfy.gmojsoski.com
handle @ntfy {
	# NO gzip — ntfy uses long-lived HTTP/WebSocket connections
	reverse_proxy http://172.17.0.1:8085
}
```

### 2c. Tunnel ingress (append to LIVE `~/.cloudflared/config.yml`, before the catch-all)

```yaml
  - hostname: ntfy.gmojsoski.com
    service: http://localhost:8080
```

(`localhost`, never `127.0.0.1` — governance rule 1.) Add the
`ntfy.gmojsoski.com` CNAME in the Cloudflare dashboard if the tunnel doesn't
auto-create it.

### 2d. Restart sequence + triple check

```bash
docker exec caddy caddy validate --config /etc/caddy/Caddyfile
cd ~/Pi-version-control/docker/caddy && docker compose restart caddy
cd ../cloudflared && docker compose restart
curl -I http://localhost:8085                                    # internal
curl -H "Host: ntfy.gmojsoski.com" http://localhost:8080         # via Caddy
curl -I https://ntfy.gmojsoski.com                               # external
./scripts/verify-services.sh                                     # from repo root
```

Mobile check: install the ntfy app, set server `https://ntfy.gmojsoski.com`,
log in as `goce`, subscribe to a test topic, then:

```bash
curl -u goce -d "hello from lemongrab" https://ntfy.gmojsoski.com/test
```

Phone must buzz with Wi-Fi off.

### 2e. Wire in the existing monitoring

- **Uptime Kuma** (both instances): Settings → Notifications → ntfy →
  server `https://ntfy.gmojsoski.com`, topic `uptime`, username/password.
  Apply to all monitors as default.
- **Health-check / backup scripts**: one-liner pattern (don't edit the
  read-only core scripts — governance rule 9; use it in NEW scripts or ask
  before touching the sacred ones):
  ```bash
  curl -fsS -u goce:PASS -H "Title: Backup failed" -H "Priority: high" \
    -d "vaultwarden backup non-zero exit" https://ntfy.gmojsoski.com/backups
  ```
- **Watchtower**: add to `docker/watchtower/docker-compose.yml` env —
  `WATCHTOWER_NOTIFICATION_URL=ntfy://goce:PASS@ntfy.gmojsoski.com/watchtower`
  (that's watchtower's own service config, allowed under scope rules).

**Rollback**: remove the Caddy block + ingress line you added, restart caddy
+ cloudflared, `./restart services/fix-external-access.sh` if needed,
`docker compose down` in `docker/ntfy`.

---

## 3. Beszel (LAN only — no Caddy, no tunnel)

1. Start hub only first:
   ```bash
   cd ~/Pi-version-control/docker/beszel && docker compose up -d beszel
   ```
2. Open `http://192.168.1.97:8086`, create the admin account, click
   **Add system**: name `lemongrab`, host `192.168.1.97`, port `45876`.
   Copy the public key it shows.
3. Paste the key into `KEY:` in the compose file, then:
   ```bash
   docker compose up -d
   ```
4. Verify: the system turns green in the hub UI within ~30s; charts appear.
   ```bash
   docker logs beszel-agent --tail 10   # should show a hub connection
   ```
5. Optional: hub → Settings → Notifications → point alerts (CPU > 90%,
   disk > 80%, system down) at `https://ntfy.gmojsoski.com/beszel`.
6. Later: run a second agent on the Pi and add it as another system.

**Rollback**: `docker compose down` in the same dir.

---

## 4. Bookkeeping (after everything verifies — append-only edits)

- [x] `docs/reference/port-map.md`: add `8084 Scrutiny (LAN only)`,
      `8085 ntfy (ntfy.gmojsoski.com)`, `8086 Beszel hub (LAN only)`,
      `45876 Beszel agent (host network, LAN only)`.
- [x] `README.md` service table: add the three rows (ntfy in the external
      table; Scrutiny + Beszel in the local-only list).
- [x] `scripts/verify-services.sh`: add `ntfy` to the SUBDOMAINS array
      (public services only — not Scrutiny/Beszel).
- [x] `docs/reference/lan-and-vpn-service-urls.md`: add Scrutiny `:8084`
      and Beszel `:8086`.
- [x] Homepage dashboard: add tiles for the three UIs.
- [ ] Uptime Kuma: add HTTP monitors for `localhost:8084` / `:8085` / `:8086`.
- [x] Commit the mirror: compose dirs + the appends above, branch
      `feature/monitoring-trio` → `develop` → `main`.
- [x] Troubleshooting log: per the checklist FAQ, smooth additions don't
      need a log entry — only log if something non-standard was required.

## Watchtower note

All three images are `:latest`/`:master-omnibus`, so Watchtower will
auto-update them nightly. If you'd rather pin (Renovate can bump them via
PRs like the other stacks), swap to pinned tags after the first successful
deploy — Scrutiny especially, since its collector touches raw disks.
