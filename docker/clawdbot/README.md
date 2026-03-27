# Clawdbot - Personal AI Assistant

Clawdbot is a personal AI assistant that runs on your own devices. This setup integrates Clawdbot with Mattermost for secure, private AI assistance.

## Security Measures

This Docker setup implements multiple security layers:

### 🔒 Network Security
- **Loopback binding**: Gateway binds to `127.0.0.1` only (not exposed externally)
- **Network isolation**: Connected only to Mattermost network
- **No public ports**: Ports only accessible from localhost

### 🛡️ Container Security
- **Non-root user**: Runs as `node` user (UID 1000) - no root privileges
- **Read-only filesystem**: Root filesystem is read-only (except mounted volumes)
- **Dropped capabilities**: All Linux capabilities dropped (`--cap-drop=ALL`)
- **No new privileges**: Prevents privilege escalation (`no-new-privileges:true`)

### 📊 Resource Limits
- **Memory**: 2GB limit (prevents memory exhaustion attacks)
- **CPU**: 1.0 CPU limit (prevents CPU exhaustion)
- **Swap**: 2GB swap limit

### 🔐 Access Control
- **Gateway token**: Required for authentication (generate with `openssl rand -hex 32`)
- **Mattermost DM policy**: Defaults to "pairing" (unknown senders require approval)
- **Channel access**: Controlled via Mattermost permissions

## Prerequisites

1. **Node.js 22.12.0+** (included in Docker image)
2. **Mattermost** running and accessible on `mattermost-net` network
3. **Mattermost bot account** with token
4. **Ollama** running on the host with model `deepseek-r1:1.5b` (e.g. `ollama serve` and `ollama pull deepseek-r1:1.5b`)
5. **Moltbot source code** at `/home/goce/Desktop/Cursor projects/moltbot` (for building the image)

## Data Storage

Configuration and workspace data are stored on the `/home` partition (not root):

- **Config**: `/home/goce/docker-data/clawdbot/config/` (contains `clawdbot.json`)
- **Workspace**: `/home/goce/docker-data/clawdbot/workspace/` (agent workspace files)
- **Temporary files**: `/tmp` (tmpfs mount, 100MB, cleared on restart)

## Setup Instructions

### 1. Create Mattermost Bot Account

1. Log into Mattermost as admin
2. Go to **System Console > Integrations > Bot Accounts**
3. Click **Add Bot Account**
4. Copy the **Bot Token** (you'll need this)

### 2. Configure Environment

The setup script (`setup.sh`) will create `.env` from `.env.example` if it doesn't exist. Edit `.env`:

```bash
cd docker/clawdbot
nano .env
```

Set:
- `CLAWDBOT_GATEWAY_TOKEN`: Generate with `openssl rand -hex 32` (or let setup.sh generate it)
- `MATTERMOST_BOT_TOKEN`: Your Mattermost bot token (e.g., `a765n69s5tr37boxm65boje47a`)
- `MATTERMOST_URL`: Should be `http://mattermost:8065` (internal Docker network)
- No API key needed for Ollama; ensure Ollama is running on the host (gateway reaches it via `host.docker.internal:11434`).

### 3. Run Setup Script

The setup script automates the build and configuration:

```bash
cd docker/clawdbot
./setup.sh
```

This will:
- Create `.env` from `.env.example` if missing
- Generate `CLAWDBOT_GATEWAY_TOKEN` if not set
- Build the Docker image
- Start the service
- Install the Mattermost plugin

### 4. Manual Build and Start (Alternative)

If you prefer manual setup:

```bash
cd docker/clawdbot
docker compose --profile all build
docker compose --profile all up -d
```

### 5. Run Onboarding (if not done automatically)

Configure Clawdbot:

```bash
docker compose exec -it clawdbot-gateway node dist/index.js onboard --no-install-daemon
```

During onboarding:
- **Gateway bind**: `loopback` or `127.0.0.1` (loopback only)
- **Gateway auth**: `token`
- **Gateway token**: Use the token from `.env`
- **Tailscale exposure**: `Off` (not needed)
- **Install Gateway daemon**: `No` (running in Docker)
- **Model provider**: Skip model configuration (Ollama is preconfigured in this setup)
- **Mattermost**: Enable and configure with your bot token

**Note**: This setup uses Ollama; the config at `/home/goce/docker-data/clawdbot/config/clawdbot.json` is already set to `ollama/deepseek-r1:1.5b` with `baseUrl: http://host.docker.internal:11434/v1`. Ensure Ollama is running on the host.

### 6. Ensure Ollama is running on the host

Before using Clawdbot, start Ollama and pull the model (if not already done):

```bash
ollama serve    # if not already running
ollama pull deepseek-r1:1.5b
```

### 7. Verify Installation

Check logs:
```bash
docker compose logs -f clawdbot-gateway
```

Check health:
```bash
docker compose exec clawdbot-gateway node dist/index.js health --token "$(grep CLAWDBOT_GATEWAY_TOKEN .env | cut -d= -f2)"
```

## Usage

### Mattermost Integration

Once configured, Clawdbot will:
- **DMs**: Respond automatically (with pairing policy by default)
- **Channels**: Respond when @mentioned (default `oncall` mode)

### Chat Modes

Configure in Clawdbot config (`~/.clawdbot/config.json5`):

```json5
{
  channels: {
    mattermost: {
      chatmode: "oncall",  // Only respond when @mentioned
      // or: "onmessage"   // Respond to every message
      // or: "onchar"       // Respond to trigger prefixes
      // oncharPrefixes: [">", "!"]
    }
  }
}
```

### DM Access Control

Default: `dmPolicy: "pairing"` (unknown senders get pairing code)

To approve a pairing:
```bash
docker compose exec clawdbot-gateway node dist/index.js pairing list mattermost
docker compose exec clawdbot-gateway node dist/index.js pairing approve mattermost <CODE>
```

For open DMs (less secure):
```json5
{
  channels: {
    mattermost: {
      dmPolicy: "open",
      allowFrom: ["*"]
    }
  }
}
```

## AI Model Configuration

This setup uses **Ollama** (local) with **DeepSeek R1 1.5B**. The configuration is stored in `/home/goce/docker-data/clawdbot/config/clawdbot.json`.

### Current Configuration

- **Model**: `ollama/deepseek-r1:1.5b`
- **Base URL**: `http://host.docker.internal:11434/v1` (gateway reaches host's Ollama)
- **API Key**: `ollama-local` (no real key; set via `OLLAMA_API_KEY` in docker-compose)

### Model Configuration in `clawdbot.json`

The config uses the `ollama` provider with `baseUrl: "http://host.docker.internal:11434/v1"` and one model `deepseek-r1:1.5b`. Primary model is `ollama/deepseek-r1:1.5b`.

### Switching Models

1. Pull another model on the host: `ollama pull <model>`
2. Edit `/home/goce/docker-data/clawdbot/config/clawdbot.json`: add or change the model `id` in `models.providers.ollama.models`, and set `agents.defaults.model.primary` to `ollama/<id>`
3. Restart: `docker compose --profile all restart clawdbot-gateway`

## Troubleshooting

### Bot not responding
- Check bot is in the channel
- Verify bot token is correct
- Check Mattermost logs: `docker compose logs mattermost`
- Check Clawdbot logs: `docker compose --profile all logs clawdbot-gateway`
- Ensure Ollama is running on the host (`ollama serve`) and model `deepseek-r1:1.5b` is pulled
- Check that the gateway can reach the host (extra_hosts: host.docker.internal)

### Connection issues
- Verify Mattermost URL is correct (`http://mattermost:8065`)
- Check both containers are on `mattermost-net` network
- Verify Mattermost is accessible: `docker compose --profile all exec clawdbot-gateway curl http://mattermost:8065/api/v4/system/ping`

### API errors (404, connection refused)
- **Connection refused**: Ollama not running on host. Run `ollama serve` and ensure port 11434 is listening.
- **404 "model not found"**: Model not pulled. Run `ollama pull deepseek-r1:1.5b` (or the model id in your config).

### Permission errors
- Container runs as `node` user (non-root) - this is intentional for security
- Check volume permissions if needed

## Maintenance

### Update Clawdbot

```bash
cd docker/clawdbot
docker compose down
docker compose build --pull
docker compose up -d
```

### Backup Configuration

Configuration is stored in `/home/goce/docker-data/clawdbot/`:

```bash
# Backup config and workspace
tar czf clawdbot-backup-$(date +%Y%m%d).tar.gz \
  /home/goce/docker-data/clawdbot/config \
  /home/goce/docker-data/clawdbot/workspace
```

### Restore Configuration

```bash
# Extract backup
tar xzf clawdbot-backup-YYYYMMDD.tar.gz -C /
```

## Security Notes

⚠️ **Important Security Considerations:**

1. **Gateway Token**: Keep it secret. Anyone with this token can access your gateway.
2. **Bot Token**: Keep it secret. Anyone with this token can impersonate your bot.
3. **DM Policy**: Default "pairing" policy prevents unauthorized access. Only change to "open" if you understand the risks.
4. **No Public Exposure**: Gateway is bound to loopback only. Do NOT expose it publicly.
5. **Resource Limits**: Limits prevent DoS attacks but may need adjustment based on usage.

## Resources

- [Clawdbot Documentation](https://docs.clawd.bot)
- [Mattermost Integration Guide](https://docs.clawd.bot/channels/mattermost)
- [Security Best Practices](https://docs.clawd.bot/security)

