# Vaultwarden Password Manager Setup

## ✅ Status: INSTALLED AND RUNNING

Vaultwarden (self-hosted Bitwarden-compatible password manager) is now set up and running on your system.

## 🔗 Access Information

- **Local Access**: http://localhost:8082
- **Domain Access**: https://vault.gmojsoski.com (via Caddy)
- **Admin Panel**: http://localhost:8082/admin
- **Admin Token**: `46qgNz55e90mHgAnYswx6fTeyjs3WDgbUyb3Ww1AkIM=` ⚠️ **SAVE THIS!**

## 📝 Next Steps

### 1. Create Your Account

1. Open http://localhost:8082 in your browser
2. Click "Create Account"
3. Enter your email and create a strong master password
4. **The first user automatically becomes admin**

### 2. Download Bitwarden Clients

Vaultwarden is compatible with all Bitwarden clients:

- **Browser Extensions**: https://bitwarden.com/download/
  - Chrome, Firefox, Edge, Safari, Opera, etc.
- **Mobile Apps**: 
  - iOS: App Store
  - Android: Google Play Store
- **Desktop Apps**: 
  - Windows, macOS, Linux

#### Linux Desktop App Installation

**Recommended: AppImage (Works Best)**

1. Download the AppImage:
   ```bash
   cd ~/Downloads
   curl -L -o Bitwarden.AppImage "https://github.com/bitwarden/clients/releases/download/desktop-v2025.12.0/Bitwarden-2025.12.0-x86_64.AppImage"
   chmod +x Bitwarden.AppImage
   ```

2. Create a desktop launcher:
   ```bash
   cat > ~/Desktop/Bitwarden.desktop << 'EOF'
   [Desktop Entry]
   Version=1.0
   Type=Application
   Name=Bitwarden
   Comment=Password Manager
   Exec=/home/goce/Downloads/Bitwarden.AppImage
   Icon=bitwarden
   Terminal=false
   Categories=Utility;Security;
   EOF
   chmod +x ~/Desktop/Bitwarden.desktop
   ```

3. Launch Bitwarden:
   - Double-click `Bitwarden.desktop` on your Desktop, or
   - Run: `~/Downloads/Bitwarden.AppImage`

**Alternative: Flatpak**
```bash
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.bitwarden.desktop
flatpak run com.bitwarden.desktop
```

**Alternative: Snap**
```bash
sudo snap install bitwarden
bitwarden
```

**Note:** AppImage is recommended as it works reliably across different Linux distributions and desktop environments.

### 3. Configure Your Client

When setting up your Bitwarden client:

1. Open client settings
2. Go to "Server" or "Self-hosted" settings
3. Set **Server URL** to: `https://vault.gmojsoski.com`
   - Or use `http://localhost:8082` for local access only
4. Save and log in with your account

## 🔒 Security Recommendations

### After Creating Your Account

1. **Disable Public Signups**:
   ```bash
   cd /mnt/ssd/docker-projects/vaultwarden
   nano docker-compose.yml
   # Change: SIGNUPS_ALLOWED: "false"
   docker compose restart
   ```

2. **Enable 2FA**:
   - Log into Vaultwarden web interface
   - Go to Settings → Two-step Login
   - Enable 2FA (Authenticator app recommended)

3. **Keep Admin Token Secure**:
   - Store the admin token in a secure location
   - You'll need it to access the admin panel
   - Admin panel: http://localhost:8082/admin

## 🛠️ Management

### Location
- **Directory**: `/mnt/ssd/docker-projects/vaultwarden`
- **Data**: `/mnt/ssd/docker-projects/vaultwarden/data`
- **Config**: `docker-compose.yml`

### Common Commands

```bash
cd /mnt/ssd/docker-projects/vaultwarden

# View logs
docker compose logs -f

# Restart
docker compose restart

# Stop
docker compose down

# Start
docker compose up -d

# Update
docker compose pull
docker compose up -d
```

### Backup

Your data is stored in `/mnt/ssd/docker-projects/vaultwarden/data/`

To backup:
```bash
# Backup the data directory
tar -czf vaultwarden-backup-$(date +%Y%m%d).tar.gz /mnt/ssd/docker-projects/vaultwarden/data/
```

## 📊 Features

- ✅ Full Bitwarden API compatibility
- ✅ End-to-end encryption
- ✅ Browser extensions support
- ✅ Mobile apps support
- ✅ Desktop apps support
- ✅ Secure password sharing
- ✅ 2FA support
- ✅ Secure notes
- ✅ Credit card storage
- ✅ Identity storage
- ✅ File attachments (with proper storage setup)

## 🔧 Configuration

Current configuration in `docker-compose.yml`:
- **Database**: SQLite (default, good for single user)
- **Signups**: Enabled (disable after creating account)
- **Web Vault**: Enabled
- **Admin Token**: Set (see above)

### Optional: Use PostgreSQL

For better performance with multiple users, you can switch to PostgreSQL. See the commented section in `docker-compose.yml`.

## 🌐 Domain Configuration

Vaultwarden is configured in Caddy to be accessible at:
- `vault.gmojsoski.com` → Port 8082

Make sure your DNS points `vault.gmojsoski.com` to your server IP, and Cloudflare tunnel is configured if using Cloudflare.

## ⚠️ Important Notes

1. **First User is Admin**: The first account created becomes the admin account
2. **Disable Signups**: After creating your account, disable public signups for security
3. **Backup Regularly**: Your password database is critical - back it up regularly
4. **Admin Token**: Keep your admin token secure - you'll need it for admin panel access
5. **HTTPS**: Always use HTTPS when accessing from outside your local network

## 🆘 Troubleshooting

### Can't Access Web Interface
```bash
# Check if container is running
docker ps | grep vaultwarden

# Check logs
docker logs vaultwarden

# Restart
cd /mnt/ssd/docker-projects/vaultwarden
docker compose restart
```

### Client Can't Connect
- Verify server URL is correct: `https://vault.gmojsoski.com`
- Check if Caddy is running and configured
- Verify DNS is pointing to your server
- Check firewall rules

### Forgot Admin Token
- Check `docker-compose.yml` in the vaultwarden directory
- Or generate a new one: `openssl rand -base64 32`
- Update `ADMIN_TOKEN` in docker-compose.yml and restart

## 📚 Resources

- **Vaultwarden GitHub**: https://github.com/dani-garcia/vaultwarden
- **Bitwarden Clients**: https://bitwarden.com/download/
- **Documentation**: https://github.com/dani-garcia/vaultwarden/wiki

