#!/bin/bash
###############################################################################
# Auto-pull and sync portfolio website
# Pulls latest changes from GitHub and syncs to Caddy's site directory
###############################################################################

# Configuration
PORTFOLIO_REPO="/home/goce/Desktop/Cursor projects/portfolio/portfolio"
CADDY_SITE="/mnt/ssd/docker-projects/caddy/site"
LOG_FILE="/var/log/portfolio-update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 664 "$LOG_FILE"
fi

# Check if repo exists
if [ ! -d "$PORTFOLIO_REPO/.git" ]; then
    log "ERROR: Portfolio repo not found at $PORTFOLIO_REPO"
    exit 1
fi

# Pull latest changes
cd "$PORTFOLIO_REPO" || exit 1
log "Checking for updates..."

# Fetch and check for updates
git fetch origin > /dev/null 2>&1

# Determine current branch (default to main)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/${CURRENT_BRANCH}" 2>/dev/null)

if [ -z "$REMOTE" ]; then
    # Try main if current branch remote doesn't exist
    REMOTE=$(git rev-parse origin/main 2>/dev/null)
    CURRENT_BRANCH="main"
fi

if [ -z "$REMOTE" ]; then
    log "ERROR: Could not determine remote branch. Available branches:"
    git branch -r | tee -a "$LOG_FILE"
    exit 1
fi

if [ "$LOCAL" = "$REMOTE" ]; then
    log "Already up to date"
    exit 0
fi

# Pull changes
log "Updates detected! Pulling latest changes from origin/${CURRENT_BRANCH}..."
git pull origin "${CURRENT_BRANCH}" 2>&1 | tee -a "$LOG_FILE"

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



