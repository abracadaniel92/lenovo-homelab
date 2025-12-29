# Tree Command Usage Guide

`tree` displays directory structures in a tree format - much better than `ls -R`.

## Basic Usage

```bash
tree                    # Current directory
tree /path              # Specific directory
tree -L 2               # Limit depth to 2 levels
tree -L 3 /mnt/ssd      # 3 levels deep, specific path
```

## Common Options

```bash
-L N                    # Limit depth to N levels
-d                      # Directories only (no files)
-a                      # Show hidden files
-h                      # Show file sizes
-s                      # Show file sizes in bytes
-t                      # Sort by modification time
-r                      # Reverse sort order
-I "pattern"            # Ignore files matching pattern
```

## Practical Examples for Your Server

### View Docker Projects Structure
```bash
# See all Docker projects
tree -L 2 /mnt/ssd/docker-projects

# See only directories
tree -d -L 2 /mnt/ssd/docker-projects

# With file sizes
tree -h -L 2 /mnt/ssd/docker-projects
```

### View Version Control Structure
```bash
# See repository structure
tree -L 2 "/home/goce/Desktop/Cursor projects/Pi-version-control"

# Ignore .git directory
tree -L 2 -I ".git" "/home/goce/Desktop/Cursor projects/Pi-version-control"

# See only important directories
tree -d -L 2 "/home/goce/Desktop/Cursor projects/Pi-version-control"
```

### View Service Configurations
```bash
# See all systemd services
tree /etc/systemd/system | grep -E "\.service$"

# See Docker compose files
tree -L 3 /mnt/ssd/docker-projects -I "data|logs|*.log"
```

### Find Specific Files
```bash
# Find all docker-compose.yml files
tree -L 3 /mnt/ssd -P "docker-compose.yml"

# Find all Caddyfiles
tree -L 3 /mnt/ssd -P "Caddyfile"

# Find all JSON configs
tree -L 3 /mnt/ssd -P "*.json"
```

## Useful Combinations

### Quick Overview
```bash
# Quick 2-level overview
tree -L 2 /mnt/ssd

# Directories only, 2 levels
tree -d -L 2 /mnt/ssd/docker-projects
```

### With File Sizes
```bash
# Show sizes in human-readable format
tree -h -L 2 /mnt/ssd/docker-projects

# Show sizes, sorted by time
tree -h -t -L 2 /mnt/ssd/docker-projects
```

### Ignore Common Directories
```bash
# Ignore data directories and logs
tree -L 2 -I "data|logs|*.log|node_modules" /mnt/ssd

# Ignore git directories
tree -L 2 -I ".git" "/home/goce/Desktop/Cursor projects"
```

## Real-World Examples

### Check Docker Project Structure
```bash
tree -L 2 /mnt/ssd/docker-projects
# Shows:
# /mnt/ssd/docker-projects
# ├── caddy
# │   ├── config
# │   ├── data
# │   └── docker-compose.yml
# ├── goatcounter
# │   └── docker-compose.yml
# └── ...
```

### View Configuration Files
```bash
tree -L 3 "/home/goce/Desktop/Cursor projects/Pi-version-control" -I ".git"
# Shows:
# Pi-version-control/
# ├── docker/
# │   ├── caddy/
# │   │   └── Caddyfile
# │   └── ...
# ├── scripts/
# │   ├── health-check-and-restart.sh
# │   └── ...
# └── ...
```

### Find Large Directories
```bash
# See structure with sizes
tree -h -L 2 /mnt/ssd | head -50

# Then use ncdu for detailed analysis
ncdu /mnt/ssd
```

## Pro Tips

### Save to File
```bash
# Save structure to file
tree -L 3 /mnt/ssd/docker-projects > docker-structure.txt

# Include in documentation
tree -L 2 "/home/goce/Desktop/Cursor projects/Pi-version-control" >> README.md
```

### Combine with Other Tools
```bash
# Find and show structure
find /mnt/ssd -name "docker-compose.yml" -exec tree -L 1 {} \;

# Count files
tree /mnt/ssd/docker-projects | tail -1
```

### Quick Directory Overview
```bash
# Most common: 2 levels, directories only
tree -d -L 2 /mnt/ssd

# With file sizes for specific project
tree -h -L 2 /mnt/ssd/docker-projects/caddy
```

## Common Use Cases

### 1. Quick Navigation
```bash
# See where everything is
tree -d -L 2 /mnt/ssd
```

### 2. Find Configuration Files
```bash
# See all config files
tree -L 3 /mnt/ssd -P "*.yml|*.yaml|*.json|Caddyfile"
```

### 3. Document Structure
```bash
# Generate structure for documentation
tree -L 2 "/home/goce/Desktop/Cursor projects/Pi-version-control" > STRUCTURE.md
```

### 4. Compare Directories
```bash
# Compare two directory structures
tree -d -L 2 /mnt/ssd/docker-projects > structure1.txt
tree -d -L 2 /backup/docker-projects > structure2.txt
diff structure1.txt structure2.txt
```

## Quick Reference

| Command | What it does |
|---------|-------------|
| `tree` | Current directory |
| `tree -L 2` | 2 levels deep |
| `tree -d` | Directories only |
| `tree -h` | Show file sizes |
| `tree -I "pattern"` | Ignore files matching pattern |
| `tree -P "pattern"` | Show only files matching pattern |
| `tree -t` | Sort by modification time |

## Most Useful Commands for Your Server

```bash
# Quick overview of everything
tree -d -L 2 /mnt/ssd

# See Docker projects
tree -L 2 /mnt/ssd/docker-projects

# See version control structure
tree -L 2 "/home/goce/Desktop/Cursor projects/Pi-version-control" -I ".git"

# Find config files
tree -L 3 /mnt/ssd -P "*.yml|*.yaml|*.json|Caddyfile|docker-compose.yml"
```

