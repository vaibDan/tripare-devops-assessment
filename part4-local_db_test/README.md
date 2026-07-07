# Part 4: Local Database Test

A local Postgres 16 instance via Docker Compose, with `hotel_bookings` and
`booking_events` created automatically on first startup.

## How the migration runs

Docker's official Postgres image auto-runs any `.sql`/`.sh` file placed in
`/docker-entrypoint-initdb.d/`, in filename order, **only the first time the
container initializes an empty data volume**. `docker-compose.yml` mounts
`./migrations` to that path, so `schema.sql` runs on first `up`
and never again — matching how real migrations behave (applied once, not
re-run every restart).

## One deliberate deviation from the suggested schema

The assignment's suggested schema doesn't declare `booking_events.booking_id`
as a foreign key to `hotel_bookings.id`. I added one anyway
(`ON DELETE CASCADE`), because without it the database allows an event to
reference a booking that doesn't exist — a real bug source in event-sourced
systems. This is a judgment call worth being able to explain, not something
silently changed.

## Setup

```bash
cd part4-local_db_test
docker compose up -d
docker compose ps          # wait until STATUS shows "healthy"
```

## Verification

```bash
# Confirm both tables exist with the right shape
docker exec -it tripare-local-db psql -U appadmin -d appdb -c "\d hotel_bookings"
docker exec -it tripare-local-db psql -U appadmin -d appdb -c "\d booking_events"

# Confirm the FK actually works (should fail with a foreign key violation)
docker exec -it tripare-local-db psql -U appadmin -d appdb -c \
  "INSERT INTO booking_events (booking_id, event_type) VALUES (gen_random_uuid(), 'test');"
```

## Resetting to re-run the migration from scratch

Since the init script only runs on an empty volume, changing
`schema.sql` won't take effect on an existing volume. To force it:

```bash
docker compose down -v   # -v removes the named volume (db_data)
docker compose up -d
```

## Connection details for Part 5 / Part 6

| | |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Database | `appdb` |
| User | `appadmin` |
| Password | `localdevpassword` |

(Local dev credentials only — matches the placeholder pattern used in
Part 1/2's RDS module, never a real secret.)
