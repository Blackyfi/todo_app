#!/bin/bash

# Automated backup script for todo-sync-server

# Configuration
BACKUP_DIR="/opt/todo_app/server/backups"
DB_PATH="/opt/todo_app/server/data/todo-sync.db"
SSL_DIR="/opt/todo_app/server/ssl"
ENV_FILE="/opt/todo_app/server/.env"
RETENTION_DAYS=30
COMPRESS_AFTER_DAYS=7

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo "[$(date)] Starting backup: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup database
if [ -f "$DB_PATH" ]; then
    echo "[$(date)] Backing up database..."
    cp "$DB_PATH" "${BACKUP_PATH}/todo-sync.db"
else
    echo "[$(date)] Warning: Database file not found"
fi

# Backup SSL certificates
if [ -d "$SSL_DIR" ]; then
    echo "[$(date)] Backing up SSL certificates..."
    cp -r "$SSL_DIR" "${BACKUP_PATH}/"
fi

# Backup .env file (without exposing it)
if [ -f "$ENV_FILE" ]; then
    echo "[$(date)] Backing up configuration..."
    cp "$ENV_FILE" "${BACKUP_PATH}/.env"
fi

# Create checksum
echo "[$(date)] Creating checksum..."
cd "$BACKUP_PATH"
sha256sum * > checksums.txt 2>/dev/null

# Compress backups older than 7 days
echo "[$(date)] Compressing old backups..."
find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup_*" -mtime +$COMPRESS_AFTER_DAYS ! -name "*.tar.gz" -exec tar -czf {}.tar.gz {} \; -exec rm -rf {} \; 2>/dev/null

# Delete backups older than retention period
echo "[$(date)] Cleaning up old backups..."
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup completed: $BACKUP_NAME"
