# Recommended Apps & Tools

This document lists recommended applications and tools for your self-hosted server setup.

## 🔍 System Monitoring

### htop / btop
**Purpose**: Better process monitoring than `top`  
**Why**: Visual, interactive process manager  
**Install**: `sudo apt install htop` or `sudo apt install btop`  
**Usage**: `htop` or `btop`

### neofetch
**Purpose**: System information display  
**Why**: Quick overview of system specs  
**Install**: `sudo apt install neofetch`  
**Usage**: `neofetch`

### glances
**Purpose**: Advanced system monitoring  
**Why**: Web-based monitoring, Docker stats, network monitoring  
**Install**: `sudo apt install glances` or `pip install glances`  
**Usage**: `glances` or `glances -w` (web interface)

## 🔒 Security Tools

### fail2ban
**Status**: ✅ Already installed  
**Purpose**: Brute force protection

### ufw (Uncomplicated Firewall)
**Purpose**: Simple firewall management  
**Why**: Easy to configure, protects against unauthorized access  
**Install**: `sudo apt install ufw`  
**Usage**: 
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 53/udp    # Pi-hole DNS
sudo ufw enable
```

### rkhunter / chkrootkit
**Purpose**: Rootkit detection  
**Why**: Security scanning for malware/rootkits  
**Install**: `sudo apt install rkhunter chkrootkit`  
**Usage**: `sudo rkhunter --check`

### unattended-upgrades
**Purpose**: Automatic security updates  
**Why**: Keeps system patched automatically  
**Install**: `sudo apt install unattended-upgrades`  
**Configure**: `sudo dpkg-reconfigure -plow unattended-upgrades`

## 📦 Package Management

### apt-file
**Purpose**: Find which package provides a file  
**Why**: Useful when you need a file but don't know the package  
**Install**: `sudo apt install apt-file`  
**Usage**: `apt-file search <filename>`

### apt-listchanges
**Purpose**: View changelogs before updates  
**Why**: See what changed before updating  
**Install**: `sudo apt install apt-listchanges`

## 🛠️ System Utilities

### tmux / screen
**Purpose**: Terminal multiplexer  
**Why**: Keep sessions running after SSH disconnect  
**Install**: `sudo apt install tmux` or `sudo apt install screen`  
**Usage**: `tmux` or `screen`

### tree
**Purpose**: Directory tree visualization  
**Why**: Better than `ls -R`  
**Install**: `sudo apt install tree`  
**Usage**: `tree -L 2`

### jq
**Purpose**: JSON processor  
**Why**: Parse JSON in scripts/CLI  
**Install**: `sudo apt install jq`  
**Usage**: `curl ... | jq`

### ripgrep (rg)
**Purpose**: Fast text search  
**Why**: Much faster than `grep`  
**Install**: `sudo apt install ripgrep` or download from GitHub  
**Usage**: `rg "pattern"`

### bat
**Purpose**: Better `cat` with syntax highlighting  
**Why**: Read files with colors and line numbers  
**Install**: Download from GitHub releases  
**Usage**: `bat file.txt`

### fd
**Purpose**: Fast file finder  
**Why**: Faster and more intuitive than `find`  
**Install**: Download from GitHub releases  
**Usage**: `fd "pattern"`

## 💾 Backup & Storage

### rsync
**Purpose**: File synchronization  
**Why**: Efficient backups, incremental sync  
**Install**: `sudo apt install rsync` (usually pre-installed)  
**Usage**: `rsync -av source/ dest/`

### rclone
**Purpose**: Cloud storage sync  
**Why**: Backup to Google Drive, Dropbox, S3, etc.  
**Install**: `curl https://rclone.org/install.sh | sudo bash`  
**Usage**: `rclone sync /local/path remote:path`

### borgbackup
**Purpose**: Deduplicating backup tool  
**Why**: Efficient, encrypted backups  
**Install**: `sudo apt install borgbackup`  
**Usage**: `borg create backup::archive /path/to/backup`

## 🌐 Network Tools

### netcat (nc)
**Purpose**: Network debugging  
**Why**: Test connections, port scanning  
**Install**: `sudo apt install netcat`  
**Usage**: `nc -zv host port`

### tcpdump / wireshark
**Purpose**: Network packet analysis  
**Why**: Debug network issues  
**Install**: `sudo apt install tcpdump wireshark`

### iftop / nethogs
**Purpose**: Network usage monitoring  
**Why**: See which processes use bandwidth  
**Install**: `sudo apt install iftop nethogs`  
**Usage**: `sudo iftop` or `sudo nethogs`

## 🐳 Docker Tools

### docker-compose
**Status**: ✅ Already installed  
**Purpose**: Multi-container Docker apps

### lazydocker
**Purpose**: Terminal UI for Docker  
**Why**: Visual Docker management  
**Install**: Download from GitHub releases  
**Usage**: `lazydocker`

### dive
**Purpose**: Docker image analysis  
**Why**: See what's in Docker images, optimize size  
**Install**: Download from GitHub releases  
**Usage**: `dive <image>`

## 📊 Log Management

### logrotate
**Purpose**: Log rotation  
**Status**: Usually pre-installed  
**Why**: Prevents logs from filling disk

### journalctl
**Purpose**: Systemd journal viewer  
**Status**: Pre-installed  
**Why**: View system logs

## 🔧 Development Tools

### git
**Status**: ✅ Already installed  
**Purpose**: Version control

### vim / nano
**Purpose**: Text editors  
**Status**: Usually pre-installed  
**Why**: Edit configs via SSH

### build-essential
**Purpose**: Compilation tools  
**Why**: Build software from source  
**Install**: `sudo apt install build-essential`

## 📡 Remote Access

### openssh-server
**Status**: ✅ Already installed  
**Purpose**: SSH access

### mosh
**Purpose**: Mobile shell  
**Why**: Better SSH for mobile/unstable connections  
**Install**: `sudo apt install mosh`  
**Usage**: `mosh user@host`

## 🎯 Priority Recommendations

### High Priority (Security & Monitoring)
1. **ufw** - Firewall (if not already configured)
2. **unattended-upgrades** - Automatic security updates
3. **htop** or **btop** - Better process monitoring
4. **glances** - Advanced monitoring

### Medium Priority (Convenience)
1. **tmux** - Terminal multiplexer (great for SSH)
2. **tree** - Directory visualization
3. **jq** - JSON processing (useful for APIs)
4. **ripgrep** - Fast text search

### Low Priority (Nice to Have)
1. **lazydocker** - Docker UI
2. **rclone** - Cloud backup
3. **neofetch** - System info display
4. **bat** - Better file viewing

## Installation Script

You can install multiple tools at once:

```bash
# High priority tools
sudo apt update
sudo apt install -y htop btop tmux tree jq ripgrep ufw unattended-upgrades glances

# Optional: rclone (cloud backup)
curl https://rclone.org/install.sh | sudo bash
```

## Notes

- **Don't install everything at once** - Install as needed
- **Test in staging first** - If possible, test on non-production
- **Monitor resources** - Some tools use more resources than others
- **Keep updated** - Regularly update installed packages

## Current Setup Assessment

Based on your setup:
- ✅ Docker & Docker Compose - Installed
- ✅ Git - Installed
- ✅ Fail2ban - Installed
- ✅ SSH - Configured
- ⚠️ Firewall (ufw) - Should configure
- ⚠️ Auto-updates - Should enable
- ⚠️ Monitoring tools - Could add

## Next Steps

1. **Security first**: Configure ufw and enable unattended-upgrades
2. **Monitoring**: Install htop/btop and glances
3. **Convenience**: Install tmux, tree, jq
4. **Backup**: Consider rclone or borgbackup

