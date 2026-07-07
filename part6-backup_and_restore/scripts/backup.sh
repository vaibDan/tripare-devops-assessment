#!/usr/bin/env bash
set -euo pipefail

CONTAINER="tripare-local-db"
DB_USER="appadmin"
DB_NAME="appdb"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/../backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/appdb_backup_${TIMESTAMP}.dump"

echo "Backing up '$DB_NAME' from container '$CONTAINER'..."

# -F c = custom format (compressed, and required for pg_restore in restore.sh).
# Dump inside the container first, then copy it out — avoids needing pg_dump
# installed on the host machine at all, only Docker.
docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -f /tmp/backup.dump # -F(format) c = dump in custom format like binary, 
docker cp "$CONTAINER":/tmp/backup.dump "$BACKUP_FILE"
docker exec "$CONTAINER" rm -f /tmp/backup.dump

echo "Backup created: $BACKUP_FILE"
echo "Size: $(du -h "$BACKUP_FILE" | cut -f1)" # du -h = human-readable size, cut -f1 = only the size column
