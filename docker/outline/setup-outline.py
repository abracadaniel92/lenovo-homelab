#!/usr/bin/env python3
"""
Outline Wiki Setup Script
Automatically creates collections and documents for your homelab documentation.
"""

import requests
import json
import sys
import os
from pathlib import Path

# Configuration
OUTLINE_URL = "http://localhost:8098"
OUTLINE_API_KEY = os.getenv("OUTLINE_API_KEY", "")

# Collections to create
COLLECTIONS = [
    {
        "name": "Infrastructure",
        "description": "Core infrastructure rules, governance, and configuration",
        "color": "#3B82F6"
    },
    {
        "name": "Services",
        "description": "Documentation for all homelab services",
        "color": "#10B981"
    },
    {
        "name": "Troubleshooting",
        "description": "Known issues, fixes, and recovery procedures",
        "color": "#EF4444"
    },
    {
        "name": "Operations",
        "description": "Daily operations, maintenance, and procedures",
        "color": "#F59E0B"
    }
]

# Documents to create
DOCUMENTS = {
    "Infrastructure": [
        {
            "title": "Infrastructure Governance Rules",
            "content": """# Infrastructure Governance Rules

This document defines the strict operating rules for the homelab infrastructure.

## 🔴 CRITICAL: Networking & Ingress (NEVER CHANGE)

### Cloudflare Tunnel Binding
- **RULE**: In `~/.cloudflared/config.yml`, the `service` URL must ALWAYS be `http://localhost:8080`
- **PROHIBITED**: NEVER use `127.0.0.1:8080`. This causes intermittent connection failures
- **WHY**: The tunnel runs in Docker with host networking; `localhost` resolves reliably via `/etc/hosts`, while `127.0.0.1` has caused loopback routing issues

### Caddy Reverse Proxy
- **Source of Truth**: `docker/caddy/Caddyfile` is the ONLY valid configuration file
- **Standard Block**: When adding a new service, use this EXACT template:
  ```
  handle @subdomain {
      reverse_proxy http://172.17.0.1:PORT
  }
  ```
- **NO Header Overrides**: DO NOT add `header_up Host {host}` or `X-Forwarded-*` unless explicitly required
- **Media Servers**: For Jellyfin/Plex/Navidrome, explicit `encode gzip` is PROHIBITED as it breaks mobile streaming

## 🛡️ Operational Safety

### Governance
- **NEVER** modify existing, working Caddyfile blocks while troubleshooting a new service
- **ALWAYS** check `usefull files/TROUBLESHOOTING_LOG.md` before suggesting a fix
- **ALWAYS** run `scripts/verify-services.sh` after any network change

### Service Addition Protocol
- Read `SERVICE_ADDITION_CHECKLIST.md` before generating config
- Check for port conflicts (`sudo ss -tulpn`) before assigning a port

## 🟢 Allowed Extensions (Append Only)

The following files are CRITICAL infrastructure. You may **ONLY** add new entries to them:
- `~/.cloudflared/config.yml`: Add new ingress rules to the list
- `docker/caddy/Caddyfile`: Add new `handle @service` blocks
- `scripts/verify-services.sh`: Add new domains to the `SUBDOMAINS` array
- `README.md`: Add new service descriptions

## 🔴 Read-Only (Core Infrastructure)

Never edit these files as part of a routine service addition:
- `scripts/enhanced-health-check.sh`
- `scripts/fix-external-access.sh`
- `scripts/backup-retention-helper.sh`
- All files in `systemd/*.service` or `systemd/*.timer`

## 🟡 Scope-Locked (Service Configs)

- `docker/<service>/docker-compose.yml` and `.env` files are **LOCKED** to that service
- You may edit a service's config ONLY if you are specifically troubleshooting that service
- **Forbidden**: Never edit `docker/jellyfin/...` when working on Paperless
"""
        },
        {
            "title": "Service Addition Checklist",
            "content": """# Service Addition Checklist

Follow this checklist whenever adding a new service to the homelab.

## 1. Docker Compose Configuration
- [ ] **Network Mode**: Unless absolutely necessary, DO NOT use `network_mode: host`
- [ ] **Port Conflicts**: Check if the port is already in use (`sudo ss -tulpn | grep :<PORT>`)
- [ ] **Data Persistence**: Ensure volumes are mapped correctly
- [ ] **Restart Policy**: Always set `restart: unless-stopped`

## 2. Caddy Configuration
- [ ] **Standard Proxy Block**: Use the standard template
- [ ] **Avoid Gzip for Media**: For media servers, explicitly DISABLE gzip if mobile clients have issues
- [ ] **Validation**: Run `docker exec caddy caddy validate --config /etc/caddy/Caddyfile` BEFORE restarting

## 3. Cloudflare Tunnel Configuration
- [ ] **Localhost Binding**: ALWAYS use `localhost:8080` for the service URL, NOT `127.0.0.1`
- [ ] **Ingress Rule**: Add the new hostname to the ingress list
- [ ] **Integrity**: Ensure no other rules have been modified

## 4. Verification (The "Triple Check")
- [ ] **Internal Check**: `curl -I http://localhost:PORT`
- [ ] **Internal Proxy Check**: `curl -H "Host: service.gmojsoski.com" http://localhost:8080`
- [ ] **External Check**: `curl -I https://service.gmojsoski.com`
- [ ] **Mobile Check**: disable Wi-Fi on phone and check if site loads

## 5. Updates
- [ ] **Scripts**: Update `scripts/verify-services.sh` to include the new domain
- [ ] **Documentation**: Update `README.md` with the new service details

## Restart Sequence
1. **Restart Caddy First**: `docker compose restart caddy`
2. **Restart Tunnel Second**: `docker compose restart` in the cloudflared folder

## Rollback Procedure
If a new service breaks things:
1. **Revert**: Delete the lines you added to `Caddyfile` and `config.yml`
2. **Reset**: Run `docker compose restart caddy`
3. **Recover**: Run `./restart services/fix-external-access.sh`
4. **Verify**: Run `./scripts/verify-services.sh`
"""
        }
    ],
    "Services": [
        {
            "title": "Service Overview",
            "content": """# Homelab Services Overview

## Running Services

### Core Infrastructure
- **Caddy** (Port 8080): Reverse proxy for all services
- **Cloudflare Tunnel**: 2 replicas for redundancy
- **Uptime Kuma** (Port 3001): Monitoring & alerts
- **Portainer** (Port 9000): Docker management UI
- **Homepage** (Port 3002): Service dashboard

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
"""
        }
    ],
    "Troubleshooting": [
        {
            "title": "Common Issues & Fixes",
            "content": """# Common Issues & Fixes

## Service Down (502 Errors)

### Symptoms
- All services accessible internally and directly via Caddy
- External access via Cloudflare Tunnel returning intermittent 502 errors
- Some services returning 502 permanently

### Fixes

#### Cloudflare Tunnel Instability
- **Issue**: Multiple `cloudflared` replicas creating too many connections
- **Fix**: Increased UDP buffer sizes to 25MB
- **Command**: `sudo sysctl -w net.core.wmem_max=26214400 net.core.rmem_max=26214400`
- **Persistence**: Added to `/etc/sysctl.d/99-cloudflared.conf`

#### Port Conflicts
- **Issue**: Services crashing due to port conflicts (e.g., AirPlay on port 5000)
- **Fix**: Disable conflicting services or change ports
- **Check**: `sudo lsof -i :PORT` or `sudo ss -tulpn | grep :PORT`

## Mobile "File Download" Issue

### Symptoms
- Mobile browsers attempting to download blank files instead of loading pages
- White screens on mobile devices

### Root Cause
- `encode gzip` in Caddyfile breaks mobile streaming for media servers
- Compression conflicts with mobile browser handling

### Fix
- Remove `encode gzip` from Jellyfin, Vaultwarden, and Paperless blocks in Caddyfile
- Restart Caddy: `docker compose restart caddy`

## Recovery Commands

If services go down:
```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/restart services/fix-external-access.sh"
```

Verify services:
```bash
./scripts/verify-services.sh
```
"""
        }
    ],
    "Operations": [
        {
            "title": "Daily Operations",
            "content": """# Daily Operations Guide

## Health Checks

### Check Service Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
systemctl status planning-poker bookmarks gokapi
```

### View Logs
```bash
# Specific service
docker compose logs -f <service>

# All services
docker ps --format "{{.Names}}" | xargs -I {} docker logs {} --tail 50
```

## Backup Procedures

### Automated Backups
- Daily backups run at 2:00 AM for critical services
- Location: `/mnt/ssd/backups/`

### Manual Backup
```bash
# All critical services
bash scripts/backup-all-critical.sh

# Individual services
bash scripts/backup-vaultwarden.sh
bash scripts/backup-nextcloud.sh
bash scripts/backup-kitchenowl.sh
bash scripts/backup-travelsync.sh
```

### Backup Retention
- Last 30 backups per service
- Managed by `scripts/backup-retention-helper.sh`

## Updates

### Update a Service
```bash
cd /home/docker-projects/<service>
docker compose pull
docker compose up -d
```

### Watchtower Auto-Updates
- Updates containers daily at 2 AM
- **Excluded** (manual updates only): Nextcloud, Vaultwarden, Jellyfin, KitchenOwl

## Monitoring

### Health Check Status
```bash
systemctl status enhanced-health-check.timer
tail -50 /var/log/enhanced-health-check.log
```

### External Monitoring
- Uptime Kuma: http://localhost:3001
- Checks every 60 seconds
- Sends alerts on failures
"""
        }
    ]
}


def create_collection(api_key, name, description, color):
    """Create a collection in Outline"""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    data = {
        "name": name,
        "description": description,
        "color": color,
        "private": False
    }
    
    response = requests.post(
        f"{OUTLINE_URL}/api/collections.create",
        headers=headers,
        json=data
    )
    
    if response.status_code == 200:
        return response.json()["data"]["id"]
    else:
        print(f"Error creating collection '{name}': {response.status_code} - {response.text}")
        return None


def create_document(api_key, collection_id, title, content):
    """Create a document in a collection"""
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    data = {
        "collectionId": collection_id,
        "title": title,
        "text": content,
        "publish": True
    }
    
    response = requests.post(
        f"{OUTLINE_URL}/api/documents.create",
        headers=headers,
        json=data
    )
    
    if response.status_code == 200:
        return response.json()["data"]["id"]
    else:
        print(f"Error creating document '{title}': {response.status_code} - {response.text}")
        return None


def main():
    if not OUTLINE_API_KEY:
        print("❌ Error: OUTLINE_API_KEY environment variable not set")
        print("\nTo get your API key:")
        print("1. Log into Outline at http://localhost:8098")
        print("2. Go to Settings → API")
        print("3. Create a new API key")
        print("4. Run: export OUTLINE_API_KEY='your-key-here'")
        print("5. Run this script again")
        sys.exit(1)
    
    print("🚀 Setting up Outline wiki...")
    print(f"📡 Connecting to {OUTLINE_URL}\n")
    
    # Test connection
    try:
        response = requests.get(f"{OUTLINE_URL}/api/auth.info", headers={
            "Authorization": f"Bearer {OUTLINE_API_KEY}"
        })
        if response.status_code != 200:
            print(f"❌ Authentication failed: {response.status_code}")
            print("Please check your API key and try again.")
            sys.exit(1)
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to Outline at {OUTLINE_URL}")
        print("Make sure Outline is running: docker compose ps")
        sys.exit(1)
    
    # Create collections
    collection_ids = {}
    print("📁 Creating collections...")
    for collection in COLLECTIONS:
        print(f"  Creating '{collection['name']}'...")
        collection_id = create_collection(
            OUTLINE_API_KEY,
            collection["name"],
            collection["description"],
            collection["color"]
        )
        if collection_id:
            collection_ids[collection["name"]] = collection_id
            print(f"  ✅ Created '{collection['name']}'")
        else:
            print(f"  ⚠️  Failed to create '{collection['name']}' (may already exist)")
    
    # Create documents
    print("\n📄 Creating documents...")
    for collection_name, documents in DOCUMENTS.items():
        if collection_name not in collection_ids:
            print(f"  ⚠️  Skipping documents for '{collection_name}' (collection not found)")
            continue
        
        collection_id = collection_ids[collection_name]
        for doc in documents:
            print(f"  Creating '{doc['title']}' in '{collection_name}'...")
            doc_id = create_document(
                OUTLINE_API_KEY,
                collection_id,
                doc["title"],
                doc["content"]
            )
            if doc_id:
                print(f"  ✅ Created '{doc['title']}'")
            else:
                print(f"  ⚠️  Failed to create '{doc['title']}' (may already exist)")
    
    print("\n✅ Setup complete!")
    print(f"\n🌐 Access your wiki at: {OUTLINE_URL}")


if __name__ == "__main__":
    main()




