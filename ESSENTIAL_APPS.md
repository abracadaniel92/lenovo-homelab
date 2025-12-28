# Essential Apps for Self-Hosted Server

## 🔴 HIGH PRIORITY (Must-Have)

These are essential for security, monitoring, and basic server management.

### 1. ufw (Uncomplicated Firewall)
**Why Essential**: First line of defense, blocks unauthorized access  
**Install**: `sudo apt install ufw`  
**Setup**:
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 222/tcp   # SSH alternate
sudo ufw allow 223/tcp   # SSH alternate
sudo ufw allow 53/udp    # Pi-hole DNS
sudo ufw enable
```
**Status**: ⚠️ **Not installed** - Install immediately

### 2. unattended-upgrades
**Why Essential**: Automatic security patches, prevents vulnerabilities  
**Install**: `sudo apt install unattended-upgrades`  
**Setup**: `sudo dpkg-reconfigure -plow unattended-upgrades`  
**Status**: ⚠️ **Not installed** - Install immediately

### 3. htop or btop
**Why Essential**: Monitor processes, CPU, memory in real-time  
**Install**: `sudo apt install htop` or `sudo apt install btop`  
**Usage**: `htop` or `btop`  
**Status**: ⚠️ **Not installed** - Install for monitoring

### 4. tmux
**Why Essential**: Keep sessions alive after SSH disconnect, run long tasks  
**Install**: `sudo apt install tmux`  
**Usage**: `tmux` (then `Ctrl+B, D` to detach, `tmux attach` to reattach)  
**Status**: ⚠️ **Not installed** - Essential for SSH management

### 5. logrotate
**Why Essential**: Prevents logs from filling disk  
**Status**: ✅ Usually pre-installed  
**Verify**: `which logrotate`

### 6. rsync
**Why Essential**: Efficient backups and file synchronization  
**Status**: ✅ Usually pre-installed  
**Verify**: `which rsync`

## 🟡 MEDIUM PRIORITY (Highly Recommended)

These improve convenience, monitoring, and backup capabilities.

### 1. glances
**Why Recommended**: Advanced system monitoring with web UI  
**Install**: `sudo apt install glances` or `pip install glances`  
**Usage**: `glances` or `glances -w` (web interface on port 61208)  
**Benefit**: Better than htop, shows Docker stats, network, disk I/O

### 2. jq
**Why Recommended**: Parse JSON in scripts, useful for APIs/webhooks  
**Install**: `sudo apt install jq`  
**Usage**: `curl ... | jq` or `cat file.json | jq`  
**Benefit**: Essential for working with APIs, webhooks, Docker APIs

### 3. tree
**Why Recommended**: Visual directory structure  
**Install**: `sudo apt install tree`  
**Usage**: `tree -L 2` (2 levels deep)  
**Benefit**: Much better than `ls -R` for understanding directory structure

### 4. rclone
**Why Recommended**: Cloud backup (Google Drive, Dropbox, S3, etc.)  
**Install**: `curl https://rclone.org/install.sh | sudo bash`  
**Usage**: `rclone sync /local/path remote:path`  
**Benefit**: Automated backups to cloud storage

### 5. ripgrep (rg)
**Why Recommended**: Fast text search (10x faster than grep)  
**Install**: `sudo apt install ripgrep`  
**Usage**: `rg "pattern"` instead of `grep -r "pattern"`  
**Benefit**: Search through codebase quickly

### 6. iftop / nethogs
**Why Recommended**: Monitor network usage per process  
**Install**: `sudo apt install iftop nethogs`  
**Usage**: `sudo iftop` or `sudo nethogs`  
**Benefit**: See which services use bandwidth

### 7. lazydocker
**Why Recommended**: Terminal UI for Docker management  
**Install**: Download from GitHub releases  
**Usage**: `lazydocker`  
**Benefit**: Visual Docker management, better than `docker ps`

### 8. neofetch
**Why Recommended**: Quick system information display  
**Install**: `sudo apt install neofetch`  
**Usage**: `neofetch`  
**Benefit**: Quick overview of system specs

## 📦 Quick Install Commands

### Install All High Priority (Must-Have)
```bash
sudo apt update
sudo apt install -y ufw unattended-upgrades htop tmux

# Configure firewall
sudo ufw allow 22/tcp
sudo ufw allow 222/tcp
sudo ufw allow 223/tcp
sudo ufw allow 53/udp
sudo ufw enable

# Configure auto-updates
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Install All Medium Priority (Recommended)
```bash
sudo apt install -y glances jq tree ripgrep iftop nethogs neofetch

# Install rclone (cloud backup)
curl https://rclone.org/install.sh | sudo bash

# Install lazydocker (Docker UI)
# Download from: https://github.com/jesseduffield/lazydocker/releases
```

## 🎯 Installation Priority Order

### Step 1: Security First (Do This Now)
```bash
sudo apt install -y ufw unattended-upgrades
sudo ufw allow 22/tcp 222/tcp 223/tcp 53/udp
sudo ufw enable
sudo dpkg-reconfigure -plow unattended-upgrades
```

### Step 2: Monitoring (Do This Next)
```bash
sudo apt install -y htop tmux glances
```

### Step 3: Convenience Tools (When You Have Time)
```bash
sudo apt install -y jq tree ripgrep neofetch
```

### Step 4: Advanced Tools (Optional)
```bash
# Cloud backup
curl https://rclone.org/install.sh | sudo bash

# Network monitoring
sudo apt install -y iftop nethogs

# Docker UI (download manually)
# lazydocker from GitHub
```

## 📊 Current Status

Based on your setup:
- ✅ **Docker** - Installed
- ✅ **Git** - Installed
- ✅ **Fail2ban** - Installed
- ✅ **rsync** - Pre-installed
- ✅ **logrotate** - Pre-installed
- ⚠️ **ufw** - **NOT INSTALLED** (Install now!)
- ⚠️ **unattended-upgrades** - **NOT INSTALLED** (Install now!)
- ⚠️ **htop/btop** - **NOT INSTALLED** (Install now!)
- ⚠️ **tmux** - **NOT INSTALLED** (Install now!)

## 🔐 Security Checklist

After installing high-priority apps:
- [ ] Firewall (ufw) configured and enabled
- [ ] Automatic security updates enabled
- [ ] Fail2ban running (✅ already done)
- [ ] SSH keys configured (not passwords)
- [ ] Regular backups configured

## 💡 Usage Tips

### tmux Basics
```bash
# Start session
tmux

# Detach (keeps running): Ctrl+B, then D
# Reattach: tmux attach
# List sessions: tmux ls
# Kill session: tmux kill-session -t 0
```

### htop Tips
- `F5` - Tree view
- `F6` - Sort by column
- `F9` - Kill process
- `q` - Quit

### glances Tips
- `h` - Help
- `q` - Quit
- `w` - Web interface mode
- Shows: CPU, RAM, disk, network, Docker stats

## 🚨 Critical: Install These First

If you only install 4 things, make it these:

1. **ufw** - Firewall protection
2. **unattended-upgrades** - Security updates
3. **htop** - Process monitoring
4. **tmux** - Session management

These are the absolute minimum for a secure, manageable server.

