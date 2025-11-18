#!/bin/bash
# ==============================================================================
# 🗄️ Automated Database Backup to AWS S3 (Disaster Recovery Script)
# ==============================================================================
#
# WHAT THIS SCRIPT DOES:
# 1. Takes a full backup (dump) of your MySQL/MariaDB database.
# 2. Compresses the backup into a lightweight .tar.gz file using today's date.
# 3. Securely uploads the compressed backup to your private Amazon S3 bucket.
# 4. Cleans up old backups from the S3 bucket (older than X days) to save money.
# 5. Deletes the local backup file to save hard drive space.
#
# ==============================================================================

# Stop the script immediately if any command fails
set -e

# ============================================
# ⚙️ CONFIGURATION (CHANGE THESE VALUES!)
# ============================================
# Note: In a real production environment, you should load these from a secure .env file.
# For simplicity in this project, we are defining them here.

DB_USER="YOUR_DATABASE_USERNAME"           # e.g., root or admin
DB_PASS="YOUR_DATABASE_PASSWORD"           # e.g., MySuperSecretPass123
DB_NAME="YOUR_DATABASE_NAME"               # The name of the database to backup
S3_BUCKET_NAME="YOUR_S3_BUCKET_NAME"       # e.g., my-company-db-backups

# Advanced Settings
RETENTION_DAYS=7                           # Delete backups in S3 older than this many days
BACKUP_DIR="/tmp/db_backups"               # Temporary folder on the server to store the dump

# ============================================
# 🛠️ DO NOT CHANGE BELOW THIS LINE
# ============================================

# Get today's date in YYYY-MM-DD-HHMMSS format
DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_FILENAME="${DB_NAME}-backup-${DATE}.sql"
COMPRESSED_FILENAME="${BACKUP_FILENAME}.tar.gz"

echo "=========================================================="
echo "🚀 Starting Database Backup Process for: ${DB_NAME}"
echo "🕒 Time: $(date)"
echo "=========================================================="

# ----------------------------------------------------
# Step 1: Create a temporary backup directory
# ----------------------------------------------------
echo "📁 Wrapping up temporary directories..."
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

# ----------------------------------------------------
# Step 2: Dump the database
# ----------------------------------------------------
echo "💾 Exporting database: ${DB_NAME}..."
# The mysqldump command extracts all tables and data into a single .sql file.
mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$BACKUP_FILENAME"

# ----------------------------------------------------
# Step 3: Compress the backup
# ----------------------------------------------------
echo "🗜️ Compressing backup to save space..."
# tar -czvf means: Create, Zip, Verbose (show output), File
tar -czvf "$COMPRESSED_FILENAME" "$BACKUP_FILENAME"

# ----------------------------------------------------
# Step 4: Upload to AWS S3
# ----------------------------------------------------
echo "☁️ Uploading compressed backup to AWS S3 bucket: ${S3_BUCKET_NAME}..."
# AWS CLI command to copy a local file to an S3 bucket
aws s3 cp "$COMPRESSED_FILENAME" "s3://${S3_BUCKET_NAME}/"

# ----------------------------------------------------
# Step 5: Clean up LOCAL files
# ----------------------------------------------------
echo "🧹 Cleaning up local temporary files..."
# Delete both the raw .sql file and the compressed .tar.gz file from the server
rm -f "$BACKUP_FILENAME" "$COMPRESSED_FILENAME"

# ----------------------------------------------------
# Step 6: Clean up OLD S3 backups (Retention Policy)
# ----------------------------------------------------
echo "⏳ Checking for backups older than ${RETENTION_DAYS} days in S3..."

# This complex AWS CLI command does the following:
# 1. Lists all files in the bucket (s3 ls)
# 2. Uses 'awk' to filter files older than our retention period
# 3. Loops through the old files and deletes them (s3 rm)
# Note: If your bucket versioning is enabled, it's safer to use S3 Lifecycle Rules instead of this.
aws s3 ls "s3://${S3_BUCKET_NAME}/" | while read -r line; do
    createDate=$(echo $line | awk '{print $1" "$2}')
    createDate=$(date -d"$createDate" +%s)
    olderThan=$(date -d"-$RETENTION_DAYS days" +%s)
    
    if [[ $createDate -lt $olderThan ]]; then
        fileName=$(echo $line | awk '{print $4}')
        
        if [[ $fileName != "" ]]; then
            echo "🗑️ Deleting old backup from S3: $fileName (older than $RETENTION_DAYS days)"
            aws s3 rm "s3://${S3_BUCKET_NAME}/$fileName"
        fi
    fi
done

echo "=========================================================="
echo "✅ Backup process completed successfully!"
echo "=========================================================="
