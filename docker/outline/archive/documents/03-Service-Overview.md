# Homelab Services Overview

## Running Services

### Core Infrastructure
- **Caddy** (Port 8080): Reverse proxy for all services
- **Cloudflare Tunnel**: 2 replicas for redundancy
- **Uptime Kuma** (Port 3001): Monitoring & alerts
- **Portainer** (Port 9000): Docker management UI
- **Homepage** (Port 8000): Service dashboard

### Media & Content
- **Jellyfin** (Port 8096): Media server (movies, TV, music, books)
- **Paperless** (Port 8097): Document management
- **Outline** (Port 8098): Wiki & knowledge base

### Productivity
- **Nextcloud** (Port 8081): Cloud storage
- **Vaultwarden** (Port 8082): Password manager
- **KitchenOwl** (Port 8092): Recipe manager & shopping lists

### Utilities
- **Gokapi** (Port 8091): File sharing
- **GoatCounter** (Port 8088): Web analytics
- **TravelSync** (Port 8000): Travel document processing
- **Bookmarks** (Port 5000): Flask bookmarks service
- **Planning Poker** (Port 3000): Planning poker web application

### Automation
- **Watchtower**: Auto-updates (daily 2 AM, with exclusions)

## Port Allocation
- Preferred range: 8000-8100
- Always check `sudo ss -tulpn` before assigning a port
- Avoid: 5000 (AirPlay conflict), 9000 (Portainer)

