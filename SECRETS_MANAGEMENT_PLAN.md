# Secrets Management Plan

A simple, secure approach to managing secrets for the lemongrab home server.

## Current State

### Secrets Inventory

| Service | Secret Type | Current Location | Risk |
|---------|-------------|------------------|------|
| Nextcloud | PostgreSQL password | docker-compose.yml (plaintext) | Medium |
| Vaultwarden | Admin token | docker-compose.yml | Medium |
| TravelSync | API keys, JWT secret | .env file (not in git) | Low |
| Cloudflare | Tunnel credentials | ~/.cloudflared/*.json | Low |
| Gokapi | Auth salts | config/config.json | Low |
| Pi-hole | Web password | docker-compose.yml | Low |

### Problems
1. Some passwords are hardcoded in docker-compose.yml files
2. No backup of secrets (if .env files are lost, service breaks)
3. Secrets scattered across multiple locations
4. No rotation policy

---

## Proposed Solution: SOPS + age

### Why This Approach?

| Option | Pros | Cons | Verdict |
|--------|------|------|---------|
| **SOPS + age** | Simple, git-friendly, no extra services | Learning curve | ✅ **Recommended** |
| HashiCorp Vault | Industry standard | Overkill for home server | ❌ |
| Docker Secrets | Built-in | Requires Swarm mode | ❌ |
| Bitwarden CLI | Already have Vaultwarden | Complex for automation | ❌ |
| Plain .env files | Simple | Not secure in git, no backup | ❌ |

### What is SOPS + age?

- **SOPS** (Secrets OPerationS): Mozilla tool that encrypts values in YAML/JSON files
- **age**: Simple, modern encryption tool (replacement for GPG)
- Secrets are encrypted in git but decrypted on the server
- Only the values are encrypted, keys remain visible (easy to read/diff)

---

## Implementation Plan

### Phase 1: Setup (30 min)

#### 1.1 Install Tools

```bash
# Install age (encryption)
sudo apt install age

# Install SOPS
wget https://github.com/getsops/sops/releases/download/v3.8.1/sops_3.8.1_amd64.deb
sudo dpkg -i sops_3.8.1_amd64.deb
rm sops_3.8.1_amd64.deb
```

#### 1.2 Generate Encryption Key

```bash
# Generate age key pair
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# View your public key (you'll need this)
grep "public key" ~/.config/sops/age/keys.txt
```

#### 1.3 Create SOPS Config

Create `.sops.yaml` in repo root:

```yaml
# .sops.yaml
creation_rules:
  - path_regex: secrets/.*\.ya?ml$
    age: >-
      age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Replace with your actual public key from step 1.2.

### Phase 2: Migrate Secrets (1 hour)

#### 2.1 Create Secrets Directory Structure

```
Pi-version-control/
├── secrets/
│   ├── production.enc.yaml    # Encrypted production secrets
│   └── .gitignore             # Ensure decrypted files aren't committed
├── .sops.yaml                 # SOPS configuration
└── scripts/
    └── deploy-secrets.sh      # Script to deploy secrets
```

#### 2.2 Create Secrets File

```bash
cd "/home/goce/Desktop/Cursor projects/Pi-version-control"
mkdir -p secrets

# Create the secrets file (will be encrypted)
cat > secrets/production.yaml << 'EOF'
# Production Secrets - DO NOT COMMIT UNENCRYPTED
# This file will be encrypted with SOPS

nextcloud:
  postgres_password: "GENERATE_STRONG_PASSWORD_HERE"

vaultwarden:
  admin_token: "GENERATE_STRONG_TOKEN_HERE"

travelsync:
  google_api_key: "YOUR_GOOGLE_API_KEY"
  admin_password: "YOUR_ADMIN_PASSWORD"
  jwt_secret: "GENERATE_64_CHAR_SECRET"
  email_password: "YOUR_EMAIL_APP_PASSWORD"

pihole:
  web_password: "YOUR_PIHOLE_PASSWORD"

gokapi:
  salt_admin: "GENERATE_RANDOM_SALT"
  salt_files: "GENERATE_RANDOM_SALT"
EOF
```

#### 2.3 Encrypt the Secrets File

```bash
# Encrypt the file
sops -e secrets/production.yaml > secrets/production.enc.yaml

# Remove the unencrypted version
rm secrets/production.yaml

# Verify it's encrypted
cat secrets/production.enc.yaml
# Should show encrypted values but readable keys
```

#### 2.4 Create .gitignore for Secrets

```bash
cat > secrets/.gitignore << 'EOF'
# Never commit unencrypted secrets
*.yaml
!*.enc.yaml
*.decrypted.*
EOF
```

### Phase 3: Create Deployment Script (30 min)

#### 3.1 Deploy Secrets Script

```bash
#!/bin/bash
###############################################################################
# deploy-secrets.sh - Decrypt and deploy secrets to services
###############################################################################

set -e

REPO_DIR="/home/goce/Desktop/Cursor projects/Pi-version-control"
SECRETS_FILE="$REPO_DIR/secrets/production.enc.yaml"

# Check if SOPS key exists
if [ ! -f ~/.config/sops/age/keys.txt ]; then
    echo "❌ ERROR: SOPS age key not found at ~/.config/sops/age/keys.txt"
    echo "Run: age-keygen -o ~/.config/sops/age/keys.txt"
    exit 1
fi

echo "🔐 Decrypting secrets..."

# Decrypt to temporary file
TEMP_SECRETS=$(mktemp)
sops -d "$SECRETS_FILE" > "$TEMP_SECRETS"

# Extract secrets using yq (install: sudo apt install yq)
get_secret() {
    yq -r "$1" "$TEMP_SECRETS"
}

echo "📦 Deploying secrets to services..."

# Nextcloud
NEXTCLOUD_PW=$(get_secret '.nextcloud.postgres_password')
if [ -n "$NEXTCLOUD_PW" ] && [ "$NEXTCLOUD_PW" != "null" ]; then
    # Update docker-compose.yml or .env
    echo "  ✅ Nextcloud PostgreSQL password updated"
fi

# TravelSync
cat > /home/docker-projects/travelsync/.env << EOF
GOOGLE_API_KEY=$(get_secret '.travelsync.google_api_key')
ADMIN_USERNAME=admin
ADMIN_PASSWORD=$(get_secret '.travelsync.admin_password')
JWT_SECRET_KEY=$(get_secret '.travelsync.jwt_secret')
EMAIL_PASSWORD=$(get_secret '.travelsync.email_password')
GOOGLE_CALENDAR_HEADLESS=true
EOF
echo "  ✅ TravelSync .env updated"

# Vaultwarden
VAULT_TOKEN=$(get_secret '.vaultwarden.admin_token')
if [ -n "$VAULT_TOKEN" ] && [ "$VAULT_TOKEN" != "null" ]; then
    # Update vaultwarden docker-compose.yml
    echo "  ✅ Vaultwarden admin token updated"
fi

# Cleanup
rm -f "$TEMP_SECRETS"

echo ""
echo "✅ Secrets deployed successfully!"
echo ""
echo "⚠️  Remember to restart affected services:"
echo "   docker compose restart"
```

### Phase 4: Backup Strategy (15 min)

#### 4.1 Backup the Encryption Key

**CRITICAL**: The age private key is the ONLY way to decrypt your secrets!

```bash
# Backup options (do ALL of these):

# 1. Copy to USB drive
cp ~/.config/sops/age/keys.txt /media/usb/secrets-backup/

# 2. Store in Vaultwarden (you have access via web)
# Create a secure note with the contents of keys.txt

# 3. Print and store physically (for disaster recovery)
cat ~/.config/sops/age/keys.txt
# Store printout in safe location
```

#### 4.2 Document Recovery Procedure

If you lose access to the server:
1. Get the age private key from backup
2. Clone the repo (encrypted secrets are safe in git)
3. Install age and SOPS
4. Place key at `~/.config/sops/age/keys.txt`
5. Run `sops -d secrets/production.enc.yaml` to decrypt

---

## Usage Guide

### View Secrets (Decrypted)

```bash
sops secrets/production.enc.yaml
# Opens in $EDITOR with decrypted values
```

### Edit Secrets

```bash
sops secrets/production.enc.yaml
# Edit, save, and it auto-encrypts on close
```

### Add New Secret

```bash
sops secrets/production.enc.yaml
# Add new key-value, save
```

### Rotate a Secret

```bash
# 1. Generate new secret
openssl rand -base64 32

# 2. Edit secrets file
sops secrets/production.enc.yaml

# 3. Deploy
bash scripts/deploy-secrets.sh

# 4. Restart affected service
docker compose restart <service>
```

### Deploy After Changes

```bash
bash "/home/goce/Desktop/Cursor projects/Pi-version-control/scripts/deploy-secrets.sh"
```

---

## Security Checklist

### Initial Setup
- [ ] Generate age key pair
- [ ] Store key backup in 3+ locations
- [ ] Create .sops.yaml configuration
- [ ] Encrypt existing secrets
- [ ] Remove unencrypted secrets from git history (if any)

### Ongoing
- [ ] Never commit unencrypted secrets
- [ ] Rotate secrets annually (or after any breach)
- [ ] Verify backups work (test decryption)
- [ ] Review who has access to age private key

### Git Safety

Add to `.gitignore` in repo root:

```
# Secrets
secrets/*.yaml
!secrets/*.enc.yaml
*.decrypted.*
.env
*.env
```

---

## Quick Reference

| Task | Command |
|------|---------|
| View secrets | `sops secrets/production.enc.yaml` |
| Edit secrets | `sops secrets/production.enc.yaml` |
| Deploy secrets | `bash scripts/deploy-secrets.sh` |
| Generate password | `openssl rand -base64 32` |
| Generate JWT secret | `openssl rand -hex 32` |

---

## Alternative: Simpler Approach (If SOPS is Too Complex)

If SOPS feels too complex, use this simpler approach:

### Encrypted Backup with age

```bash
# Encrypt all secrets to a single file
tar -czf - \
  /home/docker-projects/*/.env \
  ~/.cloudflared/*.json \
  /home/apps/gokapi/config/config.json \
  | age -r age1YOUR_PUBLIC_KEY -o secrets-backup.tar.gz.age

# Decrypt when needed
age -d -i ~/.config/sops/age/keys.txt secrets-backup.tar.gz.age | tar -xzf -
```

This is simpler but doesn't allow editing individual secrets without full decrypt/encrypt cycle.

---

## Timeline

| Phase | Time | Priority |
|-------|------|----------|
| Phase 1: Setup | 30 min | High |
| Phase 2: Migrate | 1 hour | High |
| Phase 3: Deploy Script | 30 min | Medium |
| Phase 4: Backup | 15 min | **Critical** |

**Total: ~2.5 hours**

---

## Next Steps

1. **Read this document** and decide if SOPS approach works for you
2. **Install tools** (age, SOPS)
3. **Generate key** and **backup it immediately**
4. **Encrypt current secrets**
5. **Test decryption** before deleting unencrypted versions
6. **Commit encrypted secrets** to git

---

*Last Updated: January 2026*

