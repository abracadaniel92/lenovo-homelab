# Clawdbot Security Measures

This document details all security measures implemented in the Clawdbot Docker setup.

## 🔒 Network Security

### Loopback Binding
- **Gateway binds to `127.0.0.1` only** - not accessible from external networks
- Port mapping: `127.0.0.1:18789:18789` (localhost only)
- **No public exposure** - even if ports are mapped, only accessible from the host

### Network Isolation
- Connected only to `mattermost-net` network
- Cannot communicate with other Docker networks
- Isolated from host network (except loopback)

## 🛡️ Container Security

### Non-Root Execution
- **Runs as `node` user** (UID 1000) - no root privileges
- Set in Dockerfile: `USER node`
- Prevents container escape via root privileges

### Read-Only Filesystem
- **Root filesystem is read-only** (`read_only: true`)
- Only mounted volumes are writable:
  - `/home/node/.clawdbot` (config)
  - `/home/node/clawd` (workspace)
- Prevents malicious file system modifications

### Capability Dropping
- **All Linux capabilities dropped** (`cap_drop: ALL`)
- Container cannot:
  - Modify kernel parameters
  - Access raw network sockets
  - Mount filesystems
  - Perform other privileged operations

### No New Privileges
- **`no-new-privileges:true`** prevents privilege escalation
- Even if a process tries to gain privileges, it cannot

## 📊 Resource Limits

### Memory Limits
- **2GB memory limit** (`mem_limit: 2g`)
- **2GB swap limit** (`memswap_limit: 2g`)
- Prevents memory exhaustion attacks (DoS)

### CPU Limits
- **1.0 CPU limit** (`cpus: '1.0'`)
- Prevents CPU exhaustion attacks
- Can be adjusted based on system capacity

## 🔐 Access Control

### Gateway Token Authentication
- **Required for all gateway access**
- Generated securely: `openssl rand -hex 32`
- Stored in `.env` file (not committed to git)
- **Keep this token secret** - anyone with it can access your gateway

### Mattermost Bot Token
- **Required for Mattermost integration**
- Stored in `.env` file
- **Keep this token secret** - anyone with it can impersonate your bot

### DM Access Policy
- **Default: `dmPolicy: "pairing"`**
  - Unknown senders must be approved via pairing code
  - Prevents unauthorized access
- **Open DMs** (`dmPolicy: "open"`) require explicit opt-in:
  - Must set `allowFrom: ["*"]`
  - Less secure - only use if you understand the risks

### Channel Access Control
- **Default: `groupPolicy: "allowlist"`**
  - Only approved users can interact
  - Controlled via `groupAllowFrom` list
- **Open channels** require explicit configuration

## 🚫 What's NOT Exposed

### No Public Ports
- Gateway port (18789) only accessible from localhost
- No external network exposure
- **Cloudflare Tunnel NOT needed** (internal use only)

### No Web Interface Exposure
- WebChat interface not exposed (if enabled, would be localhost only)
- Gateway API only accessible with token from localhost

### No Root Access
- Container cannot access host as root
- Cannot modify host system files
- Cannot install packages on host

## ✅ Security Best Practices Implemented

1. ✅ **Principle of Least Privilege**: Non-root user, dropped capabilities
2. ✅ **Defense in Depth**: Multiple security layers
3. ✅ **Network Isolation**: Only necessary network connections
4. ✅ **Resource Limits**: Prevents DoS attacks
5. ✅ **Read-Only Filesystem**: Prevents file system tampering
6. ✅ **No Privilege Escalation**: `no-new-privileges` flag
7. ✅ **Token Authentication**: Required for gateway access
8. ✅ **Default Secure Policies**: Pairing required for DMs

## ⚠️ Security Considerations

### What You Need to Protect

1. **`.env` file**:
   - Contains gateway token and bot token
   - **Never commit to git** (already in .gitignore)
   - Restrict file permissions: `chmod 600 .env`

2. **Gateway Token**:
   - Anyone with this token can access your gateway
   - Rotate if compromised: Generate new token and update `.env`

3. **Mattermost Bot Token**:
   - Anyone with this token can impersonate your bot
   - Rotate if compromised: Create new bot account in Mattermost

4. **Clawdbot Configuration**:
   - Stored in Docker volume `clawdbot-config`
   - May contain API keys and sensitive data
   - Backup securely if needed

### Additional Security Recommendations

1. **Firewall**: Ensure host firewall blocks external access to port 18789
2. **Regular Updates**: Keep Docker image updated: `docker compose build --pull`
3. **Monitor Logs**: Regularly check logs for suspicious activity
4. **Backup Configuration**: Backup `.env` and config volumes securely
5. **Access Logs**: Monitor Mattermost access logs for unauthorized bot usage

## 🔍 Security Audit Checklist

- [x] Non-root user execution
- [x] Read-only root filesystem
- [x] All capabilities dropped
- [x] No new privileges
- [x] Loopback-only binding
- [x] Network isolation
- [x] Resource limits (CPU/Memory)
- [x] Token authentication
- [x] Default secure DM policy
- [x] No public exposure
- [x] Health checks enabled
- [x] Restart policy configured

## 📝 Security Notes

### Why These Measures Matter

Even though Clawdbot is only used via Mattermost (not exposed publicly), these security measures protect against:

1. **Container Escape**: If a vulnerability is found in Clawdbot, non-root execution limits damage
2. **Privilege Escalation**: Dropped capabilities prevent gaining additional privileges
3. **Resource Exhaustion**: Limits prevent DoS attacks from consuming all system resources
4. **Unauthorized Access**: Token authentication and pairing policies prevent unauthorized use
5. **Data Exfiltration**: Network isolation limits what the container can access

### Trade-offs

- **Read-only filesystem**: Some operations may require writable paths (handled via volumes)
- **Resource limits**: May need adjustment if Clawdbot needs more resources for complex tasks
- **Network isolation**: Cannot access other services unless on same network (Mattermost is on shared network)

## 🆘 Incident Response

If you suspect a security breach:

1. **Immediately rotate tokens**:
   - Generate new gateway token
   - Create new Mattermost bot account
   - Update `.env` file
   - Restart container

2. **Check logs**:
   ```bash
   docker compose logs clawdbot-gateway | grep -i error
   docker compose logs mattermost | grep -i bot
   ```

3. **Review access**:
   - Check Mattermost audit logs
   - Review Clawdbot pairing approvals
   - Check for unauthorized channel access

4. **Update and rebuild**:
   ```bash
   docker compose down
   docker compose build --pull
   docker compose up -d
   ```

## 📚 References

- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Clawdbot Security Documentation](https://docs.clawd.bot/security)
- [Mattermost Security Guide](https://docs.mattermost.com/configure/security-configuration-settings.html)

