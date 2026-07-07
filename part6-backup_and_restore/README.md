# Part 6: Backup and Restore

## What these scripts do

- **`scripts/backup.sh`** — creates a timestamped `pg_dump` of `appdb` (custom
  format, `-F c`), saved to `backups/appdb_backup_<timestamp>.dump`. Each run
  produces a new file, so previous backups aren't overwritten.
- **`scripts/restore.sh`** — restores the most recent backup (or a specific
  file passed as an argument) into a **fresh** database, `appdb_restore_test`,
  never into the original `appdb`. This proves the dump file alone is enough
  to rebuild the data from nothing — the actual point of a backup/restore drill.

Both scripts run everything through `docker exec`/`docker cp`, so they only
require Docker on the host — not a local Postgres client install.

## Usage

```bash
chmod +x scripts/backup.sh scripts/restore.sh

./scripts/backup.sh
# Backup created: backups/appdb_backup_20260707_143022.dump

./scripts/restore.sh
# restores the newest file in backups/ automatically

# or restore a specific file explicitly:
./scripts/restore.sh backups/appdb_backup_20260707_143022.dump
```

## Verifying that restore actually worked

Running `restore.sh` without errors is **not** proof it worked — it only
proves `pg_restore` didn't crash. Actually confirming the data is correct
means comparing the restored database against the original:

**1. Row counts match, table by table:**

```bash
docker exec -it tripare-local-db psql -U appadmin -d appdb -c \
  "SELECT 'hotel_bookings', COUNT(*) FROM hotel_bookings
   UNION ALL SELECT 'booking_events', COUNT(*) FROM booking_events;"

docker exec -it tripare-local-db psql -U appadmin -d appdb_restore_test -c \
  "SELECT 'hotel_bookings', COUNT(*) FROM hotel_bookings
   UNION ALL SELECT 'booking_events', COUNT(*) FROM booking_events;"
```

Both queries should return identical counts.

**2. Schema matches — indexes and constraints came back too, not just data:**

```bash
docker exec -it tripare-local-db psql -U appadmin -d appdb_restore_test -c "\d hotel_bookings"
```

Confirm `idx_hotel_bookings_city_created_at` (from Part 5) and the
`fk_booking` foreign key (from Part 4) both appear — a dump that only
restored rows but silently dropped indexes/constraints would still "look"
successful at a glance.

**3. Spot-check actual row content, not just counts:**

```bash
docker exec -it tripare-local-db psql -U appadmin -d appdb -c \
  "SELECT id, city, amount FROM hotel_bookings ORDER BY id LIMIT 3;"

docker exec -it tripare-local-db psql -U appadmin -d appdb_restore_test -c \
  "SELECT id, city, amount FROM hotel_bookings ORDER BY id LIMIT 3;"
```

Same `id` values should return the same `city`/`amount` in both databases —
row counts matching alone wouldn't catch corrupted or truncated column data.

Only once all three checks pass is the restore actually verified — not just
"ran without error."

## Cleanup

```bash
docker exec -it tripare-local-db psql -U appadmin -d postgres -c \
  "DROP DATABASE appdb_restore_test;"
```
