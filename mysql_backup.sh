#!/bin/bash
# ==========================================================
# Author: Engr. M. Ali (DevOps Engineer)
# Purpose: Automated MySQL Backup Script (Per DB)
# Function: Takes MySQL backup, compresses it, and cleans 15-day-old backups
# Date: $(date +%Y-%m-%d)
# ==========================================================

# === Configuration ===
DBS=("##")      # Databases to back up
BACKUP_DIR="/"       # Directory to store backups
MYSQL_USER="#"                          # MySQL username
MYSQL_PASS="###"                   # MySQL password
DATE=$(date +%Y-%m-%d)                     # Current date
LOG_FILE="${BACKUP_DIR}/backup_log.txt"    # Log file path

# === Ensure backup directory exists ===
mkdir -p "$BACKUP_DIR"

echo "===================================================" >> "$LOG_FILE"
echo "[$(date)] Backup script initiated by Engr. M. Ali (DevOps Engineer)" >> "$LOG_FILE"
echo "[$(date)] Databases targeted: ${DBS[*]}" >> "$LOG_FILE"
echo "===================================================" >> "$LOG_FILE"

# === Loop through each database for backup ===
for DB_NAME in "${DBS[@]}"; do
    FILE_NAME="${DB_NAME}_${DATE}.sql"
    ARCHIVE_NAME="${DB_NAME}_${DATE}.tar.gz"

    echo "[$(date)] Starting backup for database: $DB_NAME" >> "$LOG_FILE"

    # Take backup
    mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASS" "$DB_NAME" > "$BACKUP_DIR/$FILE_NAME" 2>> "$LOG_FILE"

    if [ $? -eq 0 ]; then
        echo "[$(date)] Backup successful for $DB_NAME: $FILE_NAME" >> "$LOG_FILE"

        # Compress the backup
        tar -czf "$BACKUP_DIR/$ARCHIVE_NAME" -C "$BACKUP_DIR" "$FILE_NAME"
        rm -f "$BACKUP_DIR/$FILE_NAME"
        echo "[$(date)] Compression completed: $ARCHIVE_NAME" >> "$LOG_FILE"
    else
        echo "[$(date)] Backup failed for $DB_NAME. Check MySQL credentials or disk space." >> "$LOG_FILE"
        continue
    fi
done

# === After successful backup, delete backups older than 15 days ===
echo "[$(date)] Checking for backups older than 15 days to delete..." >> "$LOG_FILE"

OLD_BACKUPS=$(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +15)

if [ -n "$OLD_BACKUPS" ]; then
    echo "[$(date)] Found backups older than 15 days. Deleting the following files:" >> "$LOG_FILE"
    echo "$OLD_BACKUPS" >> "$LOG_FILE"
    find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +15 -exec rm -f {} \;
    echo "[$(date)] Old backups deleted successfully." >> "$LOG_FILE"
else
    echo "[$(date)] No backups older than 15 days found." >> "$LOG_FILE"
fi

echo "[$(date)] MySQL backup process completed successfully." >> "$LOG_FILE"
echo "===================================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
