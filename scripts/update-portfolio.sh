#!/bin/bash
###############################################################################
# Auto-pull and sync portfolio website
# Pulls latest changes from GitHub and syncs to Caddy's site directory
###############################################################################

PORTFOLIO_REPO="/home/goce/Desktop/Cursor projects/portfolio/portfolio"
CADDY_SITE="/mnt/ssd/docker-projects/caddy/site"
LOG_FILE="/var/log/portfolio-update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if repo exists
if [ ! -d "$PORTFOLIO_REPO/.git" ]; then
    log "ERROR: Portfolio repo not found at $PORTFOLIO_REPO"
    exit 1
fi

# Pull latest changes
cd "$PORTFOLIO_REPO" || exit 1
log "Pulling latest changes..."

# Fetch and check for updates
git fetch origin

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master)

if [ "$LOCAL" = "$REMOTE" ]; then
    log "Already up to date"
    exit 0
fi

# Pull changes
git pull origin main 2>/dev/null || git pull origin master

if [ $? -eq 0 ]; then
    log "Successfully pulled changes"
    
    # Sync to Caddy site directory
    log "Syncing to Caddy site..."
    rsync -av --delete --exclude='.git' "$PORTFOLIO_REPO/" "$CADDY_SITE/"
    
    if [ $? -eq 0 ]; then
        log "Successfully synced to $CADDY_SITE"
        log "Portfolio updated!"
    else
        log "ERROR: Failed to sync to Caddy site"
        exit 1
    fi
else
    log "ERROR: Failed to pull changes"
    exit 1
fi




