#!/bin/bash

###############################################################################
# Portfolio Update Script
# Checks GitHub repository for updates and deploys them
###############################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO_DIR="/tmp/portfolio"
SITE_DIR="/mnt/ssd/docker-projects/caddy/site"
REPO_URL="https://github.com/abracadaniel92/portfolio.git"
LOG_FILE="$HOME/.portfolio-update.log"

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Create log file if it doesn't exist
touch "$LOG_FILE"

# Clone repository if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    log "Repository not found, cloning..."
    git clone "$REPO_URL" "$REPO_DIR"
    log "Repository cloned successfully"
fi

# Change to repository directory
cd "$REPO_DIR"

# Fetch latest changes
log "Fetching latest changes..."
git fetch origin main > /dev/null 2>&1 || git fetch origin master > /dev/null 2>&1

# Check if there are updates
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

if [ "$LOCAL" = "$REMOTE" ]; then
    log "No updates available"
    exit 0
fi

# Updates available - pull and deploy
log "Updates detected! Pulling latest changes..."
git pull origin main > /dev/null 2>&1 || git pull origin master > /dev/null 2>&1

log "Copying files to site directory..."
# Copy all files except .git and node_modules
cd "$REPO_DIR"
cp -r css js images files favicon.ico index.html "$SITE_DIR/" 2>/dev/null || true

# Ensure proper permissions
chown -R goce:goce "$SITE_DIR" 2>/dev/null || true

log "Restarting Caddy..."
docker restart caddy > /dev/null 2>&1

log "${GREEN}Portfolio updated successfully!${NC}"
exit 0

