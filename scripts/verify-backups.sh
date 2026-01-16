#!/bin/bash
###############################################################################
# Backup Verification Script
# Checks backup integrity, age, and completeness for all critical services
###############################################################################

set -e

LOG_FILE="/var/log/backup-verification.log"
MAX_LOG_SIZE=10485760  # 10MB

# Try to create log file with proper permissions, fallback to user directory if needed
if ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_FILE="$HOME/backup-verification.log"
fi

# Rotate log
if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0) -gt $MAX_LOG_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null || true
    touch "$LOG_FILE" 2>/dev/null || true
fi

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
}

# Mattermost notification function (load from enhanced-health-check.sh pattern)
send_notification() {
    local title="$1"
    local message="$2"
    local emoji="${3:-⚠️}"
    
    # Use same webhook pattern as enhanced-health-check.sh
    MATTERMOST_WEBHOOK_URL="${MATTERMOST_WEBHOOK_URL:-https://mattermost.gmojsoski.com/hooks/bettcnqps7ngpfp74i6zux5s8w}"
    
    if [ -z "$MATTERMOST_WEBHOOK_URL" ]; then
        log "WARNING: MATTERMOST_WEBHOOK_URL not set. Cannot send notification."
        return 1
    fi
    
    read -r -d '' PAYLOAD << EOF || true
{
    "username": "System Bot",
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "${emoji} ${title}",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "${message}"
            }
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "Time: $(date '+%Y-%m-%d %H:%M:%S') | Host: $(hostname)"
                }
            ]
        }
    ]
}
EOF

    curl -s -X POST -H 'Content-type: application/json' \
        --data "$PAYLOAD" \
        "$MATTERMOST_WEBHOOK_URL" > /dev/null 2>&1 || true
}

# Check backup integrity (can tar.gz be extracted)
check_backup_integrity() {
    local backup_file="$1"
    local service_name="$2"
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR: Backup file not found: $backup_file"
        return 1
    fi
    
    # Test tar.gz integrity by listing contents (fast, non-destructive)
    if tar -tzf "$backup_file" > /dev/null 2>&1; then
        return 0
    else
        log "ERROR: Backup integrity check FAILED for $service_name: $backup_file"
        log "       Backup file appears corrupted (tar.gz extraction test failed)"
        return 1
    fi
}

# Check backup age (alert if older than threshold)
check_backup_age() {
    local backup_file="$1"
    local service_name="$2"
    local max_age_hours="${3:-48}"  # Default 48 hours
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR: Backup file not found: $backup_file"
        return 1
    fi
    
    local file_time=$(stat -c %Y "$backup_file" 2>/dev/null || echo "0")
    local current_time=$(date +%s)
    local age_seconds=$((current_time - file_time))
    local age_hours=$((age_seconds / 3600))
    local age_days=$((age_hours / 24))
    
    if [ "$age_hours" -gt "$max_age_hours" ]; then
        log "WARNING: $service_name backup is $age_days days old (${age_hours}h) - threshold: ${max_age_hours}h"
        
        # Send notification for old backups
        local age_desc=""
        if [ "$age_days" -gt 0 ]; then
            age_desc="${age_days} days"
        else
            age_desc="${age_hours} hours"
        fi
        
        send_notification "⚠️ Backup Age Warning: ${service_name}" "@here

*Service:* ${service_name}
*Backup Age:* ${age_desc} (${age_hours}h)
*Threshold:* ${max_age_hours} hours
*Backup File:* \`$(basename "$backup_file")\`

*Action Required:*
Check why backup hasn't run recently. Verify backup cron jobs are working.

*Latest Backup:*
\`$(ls -lh "$backup_file" | awk '{print $9, $5, $6, $7, $8}')\`" "⚠️"
        return 1
    else
        log "✅ $service_name backup age OK: ${age_hours}h (threshold: ${max_age_hours}h)"
        return 0
    fi
}

# Verify backup exists and get latest backup file
get_latest_backup() {
    local backup_dir="$1"
    local file_pattern="$2"
    
    if [ ! -d "$backup_dir" ]; then
        log "WARNING: Backup directory not found: $backup_dir"
        return 1
    fi
    
    local latest_backup=$(ls -t "$backup_dir"/${file_pattern} 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        log "WARNING: No backups found matching pattern: ${file_pattern}"
        return 1
    fi
    
    echo "$latest_backup"
}

# Verify backup file size (not empty or suspiciously small)
check_backup_size() {
    local backup_file="$1"
    local service_name="$2"
    local min_size_mb="${3:-1}"  # Default 1MB minimum
    
    if [ ! -f "$backup_file" ]; then
        return 1
    fi
    
    local file_size=$(stat -c %s "$backup_file" 2>/dev/null || echo "0")
    local file_size_mb=$((file_size / 1024 / 1024))
    
    if [ "$file_size_mb" -lt "$min_size_mb" ]; then
        log "WARNING: $service_name backup file suspiciously small: ${file_size_mb}MB (minimum: ${min_size_mb}MB)"
        return 1
    fi
    
    return 0
}

# Verify service backup
verify_service_backup() {
    local service_name="$1"
    local backup_dir="$2"
    local file_pattern="$3"
    local max_age_hours="${4:-48}"
    local min_size_mb="${5:-1}"
    
    log "Checking $service_name backups..."
    
    local latest_backup=$(get_latest_backup "$backup_dir" "$file_pattern")
    
    if [ -z "$latest_backup" ] || [ ! -f "$latest_backup" ]; then
        log "ERROR: No backup found for $service_name"
        send_notification "🚨 Missing Backup: ${service_name}" "@all

*Service:* ${service_name}
*Status:* No backup file found
*Backup Dir:* \`${backup_dir}\`
*Pattern:* \`${file_pattern}\`

*Action Required:*
Run backup manually: \`bash scripts/backup-${service_name,,}.sh\`
Check backup cron jobs and logs." "🚨"
        return 1
    fi
    
    # Check age
    if ! check_backup_age "$latest_backup" "$service_name" "$max_age_hours"; then
        # Age check already logged and notified
        :
    fi
    
    # Check size
    if ! check_backup_size "$latest_backup" "$service_name" "$min_size_mb"; then
        log "WARNING: $service_name backup size check failed (may be OK if service has no data)"
    fi
    
    # Check integrity
    if ! check_backup_integrity "$latest_backup" "$service_name"; then
        send_notification "🚨 Backup Corruption Detected: ${service_name}" "@all

*Service:* ${service_name}
*Backup File:* \`$(basename "$latest_backup")\`
*Status:* Corrupted (tar.gz extraction test failed)

*Action Required:*
1. Check backup file: \`ls -lh "$latest_backup"\`
2. Run new backup immediately: \`bash scripts/backup-${service_name,,}.sh\`
3. Verify old backups are intact

*Location:* \`$latest_backup\`" "🚨"
        return 1
    fi
    
    log "✅ $service_name backup verification passed: $(basename "$latest_backup")"
    return 0
}

# Main verification
log "=== Starting Backup Verification ==="

FAILED_SERVICES=()

# Vaultwarden (CRITICAL - max age: 48 hours, min size: 1MB)
if ! verify_service_backup "Vaultwarden" "/mnt/ssd/backups/vaultwarden" "vaultwarden-*.tar.gz" 48 1; then
    FAILED_SERVICES+=("Vaultwarden")
fi

# Nextcloud (CRITICAL - max age: 48 hours, min size: 10MB)
if ! verify_service_backup "Nextcloud" "/mnt/ssd/backups/nextcloud" "nextcloud-*.tar.gz" 48 10; then
    FAILED_SERVICES+=("Nextcloud")
fi

# TravelSync (IMPORTANT - max age: 72 hours, min size: 1MB)
if ! verify_service_backup "TravelSync" "/mnt/ssd/backups/travelsync" "travelsync-*.tar.gz" 72 1; then
    FAILED_SERVICES+=("TravelSync")
fi

# KitchenOwl (IMPORTANT - max age: 72 hours, min size: 1MB)
if ! verify_service_backup "KitchenOwl" "/mnt/ssd/backups/kitchenowl" "kitchenowl-*.tar.gz" 72 1; then
    FAILED_SERVICES+=("KitchenOwl")
fi

# Linkwarden (MEDIUM - max age: 96 hours, min size: 1MB)
if ! verify_service_backup "Linkwarden" "/mnt/ssd/backups/linkwarden" "linkwarden-*.tar.gz" 96 1; then
    FAILED_SERVICES+=("Linkwarden")
fi

# Summary
log "=== Backup Verification Complete ==="

if [ ${#FAILED_SERVICES[@]} -eq 0 ]; then
    log "✅ All backup verifications passed"
    exit 0
else
    log "❌ Backup verification failed for: ${FAILED_SERVICES[*]}"
    exit 1
fi

