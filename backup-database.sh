#!/bin/bash
# Database backup script for music-graph
# Backs up PostgreSQL database to Google Cloud Storage
# Usage: ./backup-database.sh [dev|prod]

set -e  # Exit on error

# Determine environment
if [ -z "$1" ]; then
  echo "Error: Environment argument required (dev or prod)"
  echo "Usage: $0 [dev|prod]"
  exit 1
fi

ENV=$1

# Validate environment
if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo "Error: Environment must be 'dev' or 'prod'"
  exit 1
fi

# Configuration
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/db-backups"
BACKUP_FILE="backup-${TIMESTAMP}.sql"
COMPRESSED_FILE="${BACKUP_FILE}.gz"
GCS_BUCKET="gs://music-graph-backups-music-graph-479719/${ENV}"
COMPOSE_FILE="docker-compose.${ENV}.yml"
LOG_FILE="/var/log/music-graph-backup.log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Log start
echo "[$(date)] Starting database backup for ${ENV} environment" | tee -a "$LOG_FILE"

# Run pg_dump from Docker container
echo "[$(date)] Running pg_dump..." | tee -a "$LOG_FILE"
cd ~/music-graph
docker-compose -f "$COMPOSE_FILE" exec -T db \
  pg_dump -U musicgraph musicgraph --clean --if-exists > "${BACKUP_DIR}/${BACKUP_FILE}"

# Check if backup file was created
if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
  echo "[$(date)] ERROR: Backup file not created" | tee -a "$LOG_FILE"
  exit 1
fi

# Get backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)
echo "[$(date)] Backup created: ${BACKUP_SIZE}" | tee -a "$LOG_FILE"

# Compress backup
echo "[$(date)] Compressing backup..." | tee -a "$LOG_FILE"
gzip "${BACKUP_DIR}/${BACKUP_FILE}"

# Get compressed size
COMPRESSED_SIZE=$(du -h "${BACKUP_DIR}/${COMPRESSED_FILE}" | cut -f1)
echo "[$(date)] Compressed to: ${COMPRESSED_SIZE}" | tee -a "$LOG_FILE"

# Upload to GCS
echo "[$(date)] Uploading to GCS..." | tee -a "$LOG_FILE"
gsutil cp "${BACKUP_DIR}/${COMPRESSED_FILE}" "${GCS_BUCKET}/${COMPRESSED_FILE}"

# Verify upload
if gsutil ls "${GCS_BUCKET}/${COMPRESSED_FILE}" > /dev/null 2>&1; then
  echo "[$(date)] ✓ Backup uploaded successfully: ${GCS_BUCKET}/${COMPRESSED_FILE}" | tee -a "$LOG_FILE"
else
  echo "[$(date)] ERROR: Backup upload failed" | tee -a "$LOG_FILE"
  exit 1
fi

# Clean up local backup
rm -f "${BACKUP_DIR}/${COMPRESSED_FILE}"
echo "[$(date)] Local backup cleaned up" | tee -a "$LOG_FILE"

# List recent backups in GCS
echo "[$(date)] Recent backups in GCS:" | tee -a "$LOG_FILE"
gsutil ls -lh "${GCS_BUCKET}/" | tail -5 | tee -a "$LOG_FILE"

echo "[$(date)] Backup complete!" | tee -a "$LOG_FILE"
