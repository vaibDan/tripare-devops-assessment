#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
CONTAINER="tripare-local-db"
DB_USER="appadmin"
ORIGINAL_DB="appdb"
RESTORE_DB="appdb_restore_test"   # a FRESH database, never the original 'appdb'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # absolute path to this script's directory
BACKUP_DIR="$SCRIPT_DIR/../backups"

# Accept a specific backup file as $1, otherwise use the most recent one.
BACKUP_FILE="${1:-}"
if [ -z "$BACKUP_FILE" ]; then
  BACKUP_FILE=$(ls -t "$BACKUP_DIR"/*.dump 2>/dev/null | head -n1)
fi

if [ -z "$BACKUP_FILE" ] || [ ! -f "$BACKUP_FILE" ]; then
  echo "No backup file found. Run backup.sh first, or pass a path explicitly:"
  echo "  ./restore.sh /path/to/backup.dump"
  exit 1
fi

echo "Restoring from: $BACKUP_FILE"
echo "Target database: $RESTORE_DB (created fresh — never overwrites '$ORIGINAL_DB')"

# Drop + recreate the target so every restore starts from a clean slate,
# proving the dump alone is enough to rebuild the database from nothing.
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS $RESTORE_DB;"
docker exec "$CONTAINER" psql -U "$DB_USER" -d postgres -c "CREATE DATABASE $RESTORE_DB;"

docker cp "$BACKUP_FILE" "$CONTAINER":/tmp/restore.dump
docker exec "$CONTAINER" pg_restore -U "$DB_USER" -d "$RESTORE_DB" /tmp/restore.dump
docker exec "$CONTAINER" rm -f /tmp/restore.dump

echo ""
echo "Restore complete into database: $RESTORE_DB"
echo "See README.md 'Verifying a restore' section for how to confirm it actually worked."
