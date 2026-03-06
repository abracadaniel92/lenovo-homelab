# Port map (host ports)

Single source of truth for which service uses which host port. Check this (and run `sudo ss -tulpn`) before assigning a new port. Preferred range: **8000–8100**.

| Port  | Service           | Domain / note                    |
|-------|-------------------|-----------------------------------|
| 80    | (Caddy via tunnel)| —                                 |
| 3000  | Planning Poker    | poker.gmojsoski.com (systemd)     |
| 3001  | Uptime Kuma       | internal only                     |
| 5000  | Bookmarks         | bookmarks.gmojsoski.com (systemd) |
| 8000  | TravelSync        | tickets.gmojsoski.com, travelsync |
| 8066  | Mattermost        | mattermost.gmojsoski.com          |
| 8080  | Caddy             | reverse proxy (tunnel → 8080)     |
| 8081  | Nextcloud         | cloud.gmojsoski.com               |
| 8082  | Vaultwarden       | (internal; Caddy uses 8083)       |
| 8083  | nginx-vaultwarden | vault.gmojsoski.com               |
| 8085  | Portfolio         | portfolio.gmojsoski.com           |
| 8088  | GoatCounter       | analytics.gmojsoski.com           |
| 8089  | Kiwix             | device-ip:8089                    |
| 8091  | Gokapi            | files.gmojsoski.com               |
| 8090  | Linkwarden        | linkwarden.gmojsoski.com          |
| 8092  | KitchenOwl        | shopping.gmojsoski.com            |
| 8096  | Jellyfin          | jellyfin.gmojsoski.com            |
| 8097  | Paperless         | paperless.gmojsoski.com           |
| 8098  | Outline           | (wiki, local only)                |
| 8099  | FreshRSS          | rss.gmojsoski.com                 |
| 8100+ | —                 | available                         |
| 9091  | Authentik         | auth.gmojsoski.com                |
| 9000  | Portainer         | internal only                     |
| 9443  | Portainer HTTPS   | internal only                     |
| 2283  | Immich            | immich.gmojsoski.com              |
| 18789 | Clawdbot          | 127.0.0.1 only                    |

**Linkwarden** and **Outline** may be in docker-compose under other paths; Caddy reverse proxy ports are in `docker/caddy/config.d/*.caddy`.
