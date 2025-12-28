# Useful Tools for Server Management

Safe, non-breaking tools that improve productivity and monitoring.

## ✅ Already Installed

- ✅ **htop** - Process monitor
- ✅ **tmux** - Terminal multiplexer
- ✅ **docker** - Container platform
- ✅ **git** - Version control
- ✅ **fail2ban** - SSH protection
- ✅ **curl/wget** - HTTP clients

## 🔧 Recommended Tools (Safe to Install)

### 1. **jq** - JSON Processor
**Why**: Parse JSON in scripts, useful for APIs/webhooks  
**Install**: `sudo apt install jq`  
**Usage**:
```bash
curl https://api.example.com/data | jq '.key'
cat config.json | jq
```

### 2. **tree** - Directory Visualization
**Why**: Better than `ls -R` for understanding structure  
**Install**: `sudo apt install tree`  
**Usage**: `tree -L 2 /mnt/ssd`

### 3. **ripgrep (rg)** - Fast Text Search
**Why**: 10x faster than grep, better defaults  
**Install**: `sudo apt install ripgrep`  
**Usage**: `rg "pattern" /path`

### 4. **glances** - Advanced System Monitor
**Why**: Better than htop, shows Docker stats, network, disk I/O  
**Install**: `sudo apt install glances`  
**Usage**: `glances` or `glances -w` (web interface)

### 5. **neofetch** - System Information
**Why**: Quick overview of system specs  
**Install**: `sudo apt install neofetch`  
**Usage**: `neofetch`

### 6. **ncdu** - Disk Usage Analyzer
**Why**: Interactive disk usage, better than `du`  
**Install**: `sudo apt install ncdu`  
**Usage**: `ncdu /` (navigate with arrow keys)

### 7. **unattended-upgrades** - Auto Security Updates
**Why**: Automatic security patches (safe, won't break services)  
**Install**: `sudo apt install unattended-upgrades`  
**Configure**: `sudo dpkg-reconfigure -plow unattended-upgrades`

### 8. **apt-listchanges** - View Changelogs
**Why**: See what changed before updating  
**Install**: `sudo apt install apt-listchanges`

## 🎨 Optional Tools (Nice to Have)

### **bat** - Better Cat
**Why**: Syntax highlighting, line numbers  
**Install**: Download from [GitHub releases](https://github.com/sharkdp/bat/releases)  
**Usage**: `bat file.txt` instead of `cat file.txt`

### **lazydocker** - Docker UI
**Why**: Visual Docker management, better than `docker ps`  
**Install**: Download from [GitHub releases](https://github.com/jesseduffield/lazydocker/releases)  
**Usage**: `lazydocker`

### **rclone** - Cloud Backup
**Why**: Backup to Google Drive, Dropbox, S3, etc.  
**Install**: `curl https://rclone.org/install.sh | sudo bash`  
**Usage**: `rclone sync /local/path remote:path`

## 🚀 Quick Install

Run the install script:

```bash
sudo bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/install-useful-tools.sh"
```

Or install manually:

```bash
# Essential tools
sudo apt update
sudo apt install -y jq tree ripgrep glances neofetch ncdu unattended-upgrades apt-listchanges

# Configure auto-updates
sudo dpkg-reconfigure -plow unattended-upgrades
```

## 📊 Tool Comparison

| Tool | Purpose | Alternative |
|------|---------|-------------|
| **jq** | JSON processing | `grep`, `sed`, `awk` |
| **tree** | Directory view | `ls -R`, `find` |
| **ripgrep** | Fast search | `grep -r` |
| **glances** | System monitor | `htop`, `top` |
| **ncdu** | Disk usage | `du -sh *` |
| **bat** | File viewer | `cat`, `less` |
| **lazydocker** | Docker UI | `docker ps`, `docker stats` |

## 💡 Usage Examples

### Monitor System
```bash
glances              # Full system monitor
htop                 # Process monitor (already installed)
ncdu /               # Disk usage analyzer
```

### Search & Find
```bash
rg "pattern" /path                    # Fast text search
tree -L 2 /mnt/ssd                   # Directory structure
find /mnt/ssd -name "*.log"           # Find files
```

### JSON Processing
```bash
curl https://api.example.com | jq    # Parse API response
cat config.json | jq '.key'          # Extract value
docker inspect container | jq         # Docker JSON
```

### Docker Management
```bash
lazydocker                            # Visual Docker UI
docker stats                          # Container stats
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 🔒 Security Tools (Already Configured)

- ✅ **fail2ban** - SSH brute force protection
- ✅ **Cloudflare Tunnel** - External protection
- ⚠️ **unattended-upgrades** - Auto security updates (recommended to install)

## 📝 Notes

- All tools are **safe** and **non-breaking**
- They don't modify service configurations
- Can be uninstalled anytime: `sudo apt remove <package>`
- **unattended-upgrades** only installs security updates (safe)

## 🎯 Priority Order

1. **jq** - Essential for working with APIs/webhooks
2. **tree** - Very useful for understanding directory structure
3. **glances** - Better monitoring than htop
4. **unattended-upgrades** - Security (safe auto-updates)
5. **ripgrep** - Faster search
6. **ncdu** - Better disk analysis
7. **neofetch** - Nice to have

## ⚠️ What NOT to Install

- ❌ **ufw** - Removed (was causing Docker issues)
- ❌ **iptables** - Complex, not needed (Cloudflare protects externally)
- ❌ **selinux/apparmor** - Can break Docker containers
- ❌ **snapd** - Can cause issues with Docker

## 🔍 Verify Installation

```bash
# Check if tools are installed
which jq tree rg glances neofetch ncdu

# Test tools
neofetch
glances
tree -L 1 /mnt/ssd
rg "pattern" /path/to/search
```

