# Part 5: Seed Data and Indexing

## Files

| File | Purpose |
|---|---|
| `seeds.sql` | ~150 bookings — matches the assignment's minimum ("at least 100") |
| `seeds_large.sql` | 50,000 bookings — used only to prove the index actually gets used at realistic scale (see below) |
| `indexes.sql` | Creates the index and runs `EXPLAIN ANALYZE` on the target query |

## Seed data

Both scripts generate random bookings spread across:
- 4 organizations
- 5 cities (`delhi`, `mumbai`, `bangalore`, `pune`, `chennai`)
- 4 statuses (`pending`, `confirmed`, `cancelled`, `completed`)
- `created_at` spread over the last 60–90 days, so some rows fall inside and
  some fall outside the "last 30 days" window the target query filters on —
  needed so the filter actually has something to filter.

`booking_events` are generated for roughly half of all bookings, 1–3 events each.

## The query being optimized

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

## The index

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

**Why these columns, in this order:** `city` is an equality match and
`created_at` is a range match in the `WHERE` clause — equality columns go
first in a composite index, range columns after. **Why `INCLUDE`:**
`org_id`, `status`, and `amount` aren't filtered on, but they're exactly what
the `SELECT`/`GROUP BY` needs — bundling them into the index lets Postgres
answer more of the query directly from the index instead of always jumping
back to the full table row.

## Verification: why the index doesn't show up on the small seed

Running `indexes.sql` against `seeds.sql` (150 rows), Postgres uses a
**Seq Scan**, not the index — and that is the *correct* choice, not a bug.
With only 150 rows, scanning the whole table is cheap enough that the extra
step of consulting an index isn't worth it. An index only pays for itself
once the table is large enough that skipping rows actually saves work.

## Verification: proving the index at realistic scale

`seeds_large.sql` reseeds the same tables with 50,000 bookings instead of
150, so there's enough data for Postgres's query planner to actually prefer
the index. Re-running `indexes.sql` against this larger dataset:

| | Seq Scan (forced for comparison) | With index (before VACUUM) | With index (after VACUUM) |
|---|---|---|---|
| Plan | Seq Scan | Bitmap Heap Scan | **Index Only Scan** |
| Rows scanned | all 50,000 | 3,353 matching rows, via 697 targeted blocks | 3,353 matching rows, straight from the index |
| Heap fetches | — | 697 blocks | **0** |
| Plan cost | 1733.68 | 987.38 | 258.65 |
| Execution time | 8.048 ms | 2.262 ms | **1.149 ms** |

At 50,000 rows, Postgres switches to using the index and the query runs
roughly **4x faster** immediately after seeding. Running `VACUUM hotel_bookings;`
afterward updates Postgres's *visibility map* — a checklist confirming which
table blocks are fully up to date — which lets the planner trust the index
completely and skip the table altogether (`Heap Fetches: 0`). This is only
possible because `org_id`, `status`, and `amount` were added via `INCLUDE`:
they aren't part of the search condition, but having them in the index means
the whole query can be answered without ever opening the table. After
`VACUUM`, the query runs roughly **7x faster** than the unindexed seq scan.

The larger the table grows, the bigger this gap gets, since a sequential
scan's cost grows with total table size while the index's cost grows only
with the number of matching rows.

## How to reproduce

```bash
# Small seed (matches assignment minimum) — index correctly NOT used here
docker exec -i tripare-local-db psql -U appadmin -d appdb < seeds.sql
docker exec -i tripare-local-db psql -U appadmin -d appdb < indexes.sql

# Large seed — index IS used (Bitmap Heap Scan), ~4x faster
docker exec -i tripare-local-db psql -U appadmin -d appdb < seeds_large.sql
docker exec -i tripare-local-db psql -U appadmin -d appdb < indexes.sql

# VACUUM updates the visibility map, letting the planner answer entirely
# from the index (Index Only Scan, Heap Fetches: 0) — ~7x faster
docker exec -i tripare-local-db psql -U appadmin -d appdb -c "VACUUM hotel_bookings;"
docker exec -i tripare-local-db psql -U appadmin -d appdb < indexes.sql
```
