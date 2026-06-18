#!/bin/bash
###############################################################################
# Pull portfolio_v2 from GitHub, build with Vite, and sync dist/ to Caddy.
###############################################################################

set -euo pipefail

PORTFOLIO_REPO="/home/goce/Desktop/Cursor projects/portfolio_v2"
CADDY_SITE="/mnt/ssd/docker-projects/caddy/site"
LOG_FILE="/var/log/portfolio-update.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

ensure_node() {
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        return 0
    fi

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1090,SC1091
        . "$NVM_DIR/nvm.sh"
    fi

    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        log "ERROR: node/npm not found. Install Node 20+ or load nvm."
        exit 1
    fi
}

install_deps() {
    if npm ci; then
        return 0
    fi

    log "WARN: npm ci failed; falling back to npm install"
    npm install
}

# Create log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chmod 664 "$LOG_FILE"
fi

if [ ! -d "$PORTFOLIO_REPO/.git" ]; then
    log "ERROR: Portfolio repo not found at $PORTFOLIO_REPO"
    exit 1
fi

if [ ! -d "$CADDY_SITE" ]; then
    log "ERROR: Caddy site directory not found at $CADDY_SITE"
    exit 1
fi

cd "$PORTFOLIO_REPO" || exit 1
log "Checking for updates in portfolio_v2..."

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

if [ "$LOCAL" != "$REMOTE" ]; then
    log "Updates detected! Pulling latest from origin/${CURRENT_BRANCH}..."
    git pull --ff-only origin "${CURRENT_BRANCH}" 2>&1 | tee -a "$LOG_FILE"
else
    log "Git already up to date on origin/${CURRENT_BRANCH}"
fi

COMMIT=$(git rev-parse --short HEAD)
log "Building portfolio_v2 (${COMMIT}) with Node $(node -v)..."

ensure_node
install_deps
npm run build 2>&1 | tee -a "$LOG_FILE"

if [ ! -d "dist" ]; then
    log "ERROR: Build did not produce dist/"
    exit 1
fi

log "Syncing dist/ to Caddy site..."
rsync -av --delete dist/ "$CADDY_SITE/" 2>&1 | tee -a "$LOG_FILE"

log "Successfully deployed portfolio_v2 (${COMMIT}) to $CADDY_SITE"
log "Portfolio updated!"
