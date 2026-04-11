#!/bin/bash
###############################################################################
# Pull Centar Srbija Stil from GitHub and rebuild/restart the Docker service
###############################################################################

set -euo pipefail

CSS_REPO="/home/goce/Desktop/Cursor projects/centar-srbija-stil"
COMPOSE_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control/docker/centar-srbija-stil"
LOG_FILE="/home/goce/Desktop/Cursor projects/Pi-version-control/logs/css-update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

if [ ! -d "$CSS_REPO/.git" ]; then
    log "ERROR: Centar Srbija Stil repo not found at $CSS_REPO"
    exit 1
fi

if [ ! -f "$COMPOSE_DIR/docker-compose.yml" ]; then
    log "ERROR: docker-compose.yml not found at $COMPOSE_DIR"
    exit 1
fi

cd "$CSS_REPO" || exit 1
log "Checking for updates..."

git fetch origin >/dev/null 2>&1

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/${CURRENT_BRANCH}" 2>/dev/null)

if [ -z "$REMOTE" ]; then
    REMOTE=$(git rev-parse origin/main 2>/dev/null)
    CURRENT_BRANCH="main"
fi

if [ -z "$REMOTE" ]; then
    log "ERROR: Could not determine remote branch. Available branches:"
    git branch -r | tee -a "$LOG_FILE"
    exit 1
fi

if [ "$LOCAL" = "$REMOTE" ]; then
    log "Already up to date (origin/${CURRENT_BRANCH})"
    exit 0
fi

log "Updates detected! Pulling latest from origin/${CURRENT_BRANCH}..."
git pull origin "${CURRENT_BRANCH}" 2>&1 | tee -a "$LOG_FILE"

log "Building and restarting container..."
cd "$COMPOSE_DIR" || exit 1
docker compose build 2>&1 | tee -a "$LOG_FILE"
docker compose up -d 2>&1 | tee -a "$LOG_FILE"

log "css.gmojsoski.com deploy complete."
