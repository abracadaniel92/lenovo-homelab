# Clawdbot Implementation Summary

## Overview

Clawdbot (Moltbot) has been successfully integrated into the homelab infrastructure as an AI assistant bot for Mattermost. The implementation uses local Ollama (DeepSeek R1 1.5B) for AI responses; no cloud API required.

## Implementation Date

January 27, 2026

## Architecture

- **Service**: Clawdbot Gateway
- **Port**: 18789 (loopback only, not exposed externally)
- **Network**: Connected to `mattermost-net` for Mattermost integration
- **AI Provider**: Ollama (local, OpenAI-compatible API on host)
- **Model**: `deepseek-r1:1.5b`
- **Storage**: `/home/goce/docker-data/clawdbot/` (on /home partition)

## Key Features

1. **Secure Configuration**
   - Loopback-only binding (127.0.0.1)
   - Non-root user execution
   - Read-only filesystem
   - Dropped capabilities
   - Resource limits (2GB RAM, 1 CPU)

2. **Mattermost Integration**
   - Bot token authentication
   - Channel and DM support
   - @mention-based responses in channels
   - Open DM policy for testing

3. **Ollama (local LLM)**
   - Gateway reaches host via `host.docker.internal:11434`
   - Model: deepseek-r1:1.5b (reasoning-capable, no API key)
   - All inference on host; no cloud cost

## Configuration Files

- **Docker Compose**: `docker/clawdbot/docker-compose.yml`
- **Dockerfile**: `docker/clawdbot/Dockerfile`
- **Config**: `/home/goce/docker-data/clawdbot/config/clawdbot.json`
- **Workspace**: `/home/goce/docker-data/clawdbot/workspace/`

## Environment Variables

Required in `.env`:
- `CLAWDBOT_GATEWAY_TOKEN`: Gateway authentication token
- `MATTERMOST_BOT_TOKEN`: Mattermost bot account token
- `MATTERMOST_URL`: `http://mattermost:8065`
- Ollama runs on the host (no API key); gateway uses `OLLAMA_API_KEY=ollama-local` and `host.docker.internal` to reach it.

## Setup Process

1. Created Mattermost bot account
2. Configured Docker Compose with security measures
3. Set up bind mounts to /home partition (avoid root partition)
4. Configured Ollama provider (host.docker.internal:11434)
5. Installed Mattermost plugin
6. Tested and verified functionality

## Troubleshooting History

- **2026-02-17**: Switched from Google Gemini to local Ollama (see TROUBLESHOOTING_LOG.md).
- **Earlier**: Model not found (404) with Gemini v1; resolved with v1beta and gemini-2.5-flash.

## Current Status

✅ **Working**: Bot responds to messages in Mattermost
✅ **Configured**: Ollama (local DeepSeek R1 1.5B)
✅ **Secured**: All security measures in place
✅ **Documented**: README and SECURITY.md updated

## Future Considerations

- Ensure Ollama is running on the host before/after reboot (e.g. systemd user service or startup script).
- Consider failover to other Ollama models if needed.
- Evaluate performance and adjust resource limits if necessary.

## References

- [Clawdbot Documentation](https://docs.clawd.bot)
- [Mattermost Integration](https://docs.clawd.bot/channels/mattermost)
- [Ollama](https://ollama.com)

