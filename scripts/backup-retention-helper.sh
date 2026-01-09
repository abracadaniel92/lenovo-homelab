#!/bin/bash
###############################################################################
# Smart Backup Retention Helper
# Implements multi-tier retention policy for backups
###############################################################################

# Usage: smart_retention_cleanup <backup_dir> <file_pattern> <description>
# Example: smart_retention_cleanup "/mnt/ssd/backups/vaultwarden" "vaultwarden-*.tar.gz" "Vaultwarden"

smart_retention_cleanup() {
    local BACKUP_DIR="$1"
    local FILE_PATTERN="$2"
    local DESCRIPTION="${3:-Backup}"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "⚠️  Directory not found: $BACKUP_DIR"
        return 1
    fi
    
    cd "$BACKUP_DIR" || return 1
    
    # Get all matching backup files, sorted by modification time (newest first)
    local FILES
    FILES=$(ls -t ${FILE_PATTERN} 2>/dev/null)
    
    if [ -z "$FILES" ]; then
        echo "ℹ️  No backup files found matching pattern: ${FILE_PATTERN}"
        return 0
    fi
    
    local KEEP_COUNT=0
    local DELETE_COUNT=0
    local CURRENT_TIME=$(date +%s)
    local ONE_HOUR=$((60 * 60))
    local ONE_DAY=$((24 * ONE_HOUR))
    local ONE_WEEK=$((7 * ONE_DAY))
    local ONE_MONTH=$((30 * ONE_DAY))
    local ONE_YEAR=$((365 * ONE_DAY))
    
    # Counters for each tier
    local HOURLY_COUNT=0
    local DAILY_COUNT=0
    local WEEKLY_COUNT=0
    local MONTHLY_COUNT=0
    local YEARLY_COUNT=0
    
    # Files to keep
    local KEEP_FILES=()
    
    # Retention policy:
    # - Keep last 6 hourly backups (within 6 hours)
    # - Keep last 5 daily backups (one per day, within 5 days)
    # - Keep last 4 weekly backups (one per week, within 4 weeks)
    # - Keep last 2 monthly backups (one per month, within 2 months)
    # - Keep last 1 yearly backup (within 1 year)
    
    local LAST_DAILY_TIME=0
    local LAST_WEEKLY_TIME=0
    local LAST_MONTHLY_TIME=0
    local LAST_YEARLY_TIME=0
    
    while IFS= read -r file; do
        local FILE_TIME=$(stat -c %Y "$file" 2>/dev/null || echo "0")
        local AGE=$((CURRENT_TIME - FILE_TIME))
        
        # Determine which tier this file belongs to
        if [ $AGE -le $((6 * ONE_HOUR)) ]; then
            # Within 6 hours - hourly backup
            if [ $HOURLY_COUNT -lt 6 ]; then
                KEEP_FILES+=("$file")
                KEEP_COUNT=$((KEEP_COUNT + 1))
                HOURLY_COUNT=$((HOURLY_COUNT + 1))
            fi
        elif [ $AGE -le $((5 * ONE_DAY)) ]; then
            # Within 5 days - daily backup (keep one per day)
            if [ $DAILY_COUNT -lt 5 ]; then
                # Keep if this is a different day than the last kept daily backup
                local FILE_DATE=$(date -d "@$FILE_TIME" +%Y%m%d)
                local LAST_DAILY_DATE=$(date -d "@$LAST_DAILY_TIME" +%Y%m%d 2>/dev/null || echo "")
                
                if [ "$FILE_DATE" != "$LAST_DAILY_DATE" ]; then
                    KEEP_FILES+=("$file")
                    KEEP_COUNT=$((KEEP_COUNT + 1))
                    DAILY_COUNT=$((DAILY_COUNT + 1))
                    LAST_DAILY_TIME=$FILE_TIME
                fi
            fi
        elif [ $AGE -le $((4 * ONE_WEEK)) ]; then
            # Within 4 weeks - weekly backup (keep one per week)
            if [ $WEEKLY_COUNT -lt 4 ]; then
                # Keep if this is a different week than the last kept weekly backup
                local FILE_WEEK=$(date -d "@$FILE_TIME" +%Y-%W)
                local LAST_WEEKLY_WEEK=$(date -d "@$LAST_WEEKLY_TIME" +%Y-%W 2>/dev/null || echo "")
                
                if [ "$FILE_WEEK" != "$LAST_WEEKLY_WEEK" ]; then
                    KEEP_FILES+=("$file")
                    KEEP_COUNT=$((KEEP_COUNT + 1))
                    WEEKLY_COUNT=$((WEEKLY_COUNT + 1))
                    LAST_WEEKLY_TIME=$FILE_TIME
                fi
            fi
        elif [ $AGE -le $((2 * ONE_MONTH)) ]; then
            # Within 2 months - monthly backup (keep one per month)
            if [ $MONTHLY_COUNT -lt 2 ]; then
                # Keep if this is a different month than the last kept monthly backup
                local FILE_MONTH=$(date -d "@$FILE_TIME" +%Y%m)
                local LAST_MONTHLY_MONTH=$(date -d "@$LAST_MONTHLY_TIME" +%Y%m 2>/dev/null || echo "")
                
                if [ "$FILE_MONTH" != "$LAST_MONTHLY_MONTH" ]; then
                    KEEP_FILES+=("$file")
                    KEEP_COUNT=$((KEEP_COUNT + 1))
                    MONTHLY_COUNT=$((MONTHLY_COUNT + 1))
                    LAST_MONTHLY_TIME=$FILE_TIME
                fi
            fi
        elif [ $AGE -le $ONE_YEAR ]; then
            # Within 1 year - yearly backup (keep one per year)
            if [ $YEARLY_COUNT -lt 1 ]; then
                # Keep if this is a different year than the last kept yearly backup
                local FILE_YEAR=$(date -d "@$FILE_TIME" +%Y)
                local LAST_YEARLY_YEAR=$(date -d "@$LAST_YEARLY_TIME" +%Y 2>/dev/null || echo "")
                
                if [ "$FILE_YEAR" != "$LAST_YEARLY_YEAR" ]; then
                    KEEP_FILES+=("$file")
                    KEEP_COUNT=$((KEEP_COUNT + 1))
                    YEARLY_COUNT=$((YEARLY_COUNT + 1))
                    LAST_YEARLY_TIME=$FILE_TIME
                fi
            fi
        fi
        # Files older than 1 year are automatically not kept
    done <<< "$FILES"
    
    # Delete files not in KEEP_FILES list
    local TOTAL_FILES=$(echo "$FILES" | wc -l)
    
    while IFS= read -r file; do
        local KEEP=false
        for keep_file in "${KEEP_FILES[@]}"; do
            if [ "$file" == "$keep_file" ]; then
                KEEP=true
                break
            fi
        done
        
        if [ "$KEEP" = false ]; then
            rm -f "$file"
            DELETE_COUNT=$((DELETE_COUNT + 1))
        fi
    done <<< "$FILES"
    
    # Summary
    echo "🧹 Cleaned ${DESCRIPTION} backups:"
    echo "   📊 Total files: ${TOTAL_FILES}"
    echo "   ✅ Kept: ${KEEP_COUNT} (${HOURLY_COUNT} hourly, ${DAILY_COUNT} daily, ${WEEKLY_COUNT} weekly, ${MONTHLY_COUNT} monthly, ${YEARLY_COUNT} yearly)"
    echo "   🗑️  Deleted: ${DELETE_COUNT}"
}

# Export function for use in other scripts
export -f smart_retention_cleanup






