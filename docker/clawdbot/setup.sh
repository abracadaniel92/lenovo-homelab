#!/usr/bin/env bash
set -euo pipefail

# Clawdbot Docker Setup Script
# This script helps set up Clawdbot with Mattermost integration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🦞 Clawdbot Docker Setup"
echo "========================"
echo ""

# Check if .env exists
if [[ ! -f .env ]]; then
    echo "📝 Creating .env file from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
fi

# Generate gateway token if not set
if ! grep -q "^CLAWDBOT_GATEWAY_TOKEN=.*[^=]$" .env 2>/dev/null || grep -q "^CLAWDBOT_GATEWAY_TOKEN=$" .env; then
    echo "🔑 Generating secure gateway token..."
    if command -v openssl >/dev/null 2>&1; then
        TOKEN=$(openssl rand -hex 32)
    else
        TOKEN=$(python3 -c "import secrets; print(secrets.token_hex(32))")
    fi
    if grep -q "^CLAWDBOT_GATEWAY_TOKEN=" .env; then
        sed -i "s/^CLAWDBOT_GATEWAY_TOKEN=.*/CLAWDBOT_GATEWAY_TOKEN=$TOKEN/" .env
    else
        echo "CLAWDBOT_GATEWAY_TOKEN=$TOKEN" >> .env
    fi
    echo "✅ Generated gateway token"
    echo ""
fi

echo "📋 Configuration Checklist:"
echo ""
echo "1. ✅ Gateway token: Generated"
echo ""
echo "2. ⚠️  Mattermost Bot Token:"
echo "   - Go to Mattermost: System Console > Integrations > Bot Accounts"
echo "   - Create a bot account and copy the token"
echo "   - Set MATTERMOST_BOT_TOKEN in .env"
echo ""
echo "3. ✅ Mattermost URL: Set to http://mattermost:8065 (internal Docker network)"
echo ""
echo "📝 Edit .env file to add your Mattermost bot token:"
echo "   nano .env"
echo ""
read -p "Press Enter when you've configured MATTERMOST_BOT_TOKEN in .env, or Ctrl+C to cancel..."

# Verify Mattermost token is set
if ! grep -q "^MATTERMOST_BOT_TOKEN=.*[^=]$" .env || grep -q "^MATTERMOST_BOT_TOKEN=$" .env; then
    echo "⚠️  Warning: MATTERMOST_BOT_TOKEN appears to be empty in .env"
    echo "   Continuing anyway, but you'll need to set it before starting..."
fi

echo ""
echo "🔨 Building Docker image..."
docker compose --profile all build

echo ""
echo "🚀 Starting Clawdbot gateway..."
docker compose --profile all up -d

echo ""
echo "⏳ Waiting for gateway to start..."
sleep 5

echo ""
echo "📦 Installing Mattermost plugin..."
# Try local source first, fallback to npm
if [[ -d "/home/goce/Desktop/Cursor projects/moltbot/extensions/mattermost" ]]; then
    docker compose --profile all exec -T clawdbot-gateway node dist/index.js plugins install /app/extensions/mattermost || \
    docker compose --profile all exec -T clawdbot-gateway node dist/index.js plugins install @clawdbot/mattermost
else
    docker compose --profile all exec -T clawdbot-gateway node dist/index.js plugins install @clawdbot/mattermost
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Next steps:"
echo "   1. Run onboarding: docker compose --profile all exec -it clawdbot-gateway node dist/index.js onboard --no-install-daemon"
echo "   2. Check logs: docker compose --profile all logs -f clawdbot-gateway"
echo "   3. Read README.md for detailed configuration"
echo ""

