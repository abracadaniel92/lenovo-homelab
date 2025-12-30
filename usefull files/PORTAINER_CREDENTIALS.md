# Portainer Login Information

## 🔐 First Time Access

**Portainer has NO default credentials.** You create your admin account on first access.

### Steps:

1. **Open Portainer**: http://localhost:9000
2. **You'll see a setup screen** asking you to:
   - Create a username
   - Create a password (minimum 12 characters)
   - Confirm password
3. **Select "Docker"** as your environment
4. **Click "Get Started"**

## 🔑 If You Forgot Your Password

### Quick Fix: Use the Reset Script

The easiest way to reset Portainer is to use the provided script:

```bash
cd "/home/goce/Desktop/Cursor projects/Lenovo scripts"
./reset-portainer.sh
```

Or for non-interactive use (auto-confirm):
```bash
./reset-portainer.sh --yes
```

This script will:
1. Stop Portainer
2. Remove the data volume (deletes all settings)
3. Restart Portainer
4. You'll see the setup screen to create a new admin account

### Diagnose the Issue First

Before resetting, you can diagnose the issue:

```bash
cd "/home/goce/Desktop/Cursor projects/Lenovo scripts"
./diagnose-portainer.sh
```

This will tell you:
- If Portainer is running
- If an admin account exists
- What the issue is

### Option 1: Reset via Portainer Volume (Manual)

```bash
# Stop Portainer
cd /mnt/ssd/docker-projects/portainer
docker compose down

# Remove the data volume (WARNING: This deletes all Portainer settings)
# Note: Volume name may be portainer-data or portainer_portainer-data
docker volume rm portainer_portainer-data || docker volume rm portainer-data

# Start Portainer again
docker compose up -d

# You'll see the setup screen again to create a new admin account
```

### Option 2: Access Portainer Data Directly

Portainer stores credentials in its data volume. You can check if an admin exists:

```bash
# Check if admin account exists
docker exec portainer ls -la /data/

# View Portainer database (if you have sqlite3)
docker exec portainer ls -la /data/portainer.db
```

## 📝 Common Defaults (If You Set One)

Some people use these common patterns:
- Username: `admin`
- Password: Something you set during first setup

**There is NO default password** - you must have created one when you first accessed Portainer.

## 🔍 Check If Admin Account Exists

```bash
# Try to access Portainer API
curl http://localhost:9000/api/status

# If you get a response, Portainer is running
# If you see a setup screen in browser, no admin exists yet
```

## 💡 Recommendation

If you can't remember your credentials:
1. Try common passwords you use
2. If that doesn't work, reset Portainer (Option 1 above)
3. Create a new admin account
4. **Write down your credentials** in a secure password manager

## 🔒 Security Note

- Portainer has full access to all Docker containers
- Use a strong password (minimum 12 characters)
- Consider enabling 2FA if available
- Don't expose Portainer publicly without authentication

