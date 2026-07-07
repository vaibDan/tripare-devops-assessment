
CREATE INDEX IF NOT EXISTS idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);

-- Refresh planner statistics so the query planner knows about the
-- new index and current data distribution.
ANALYZE hotel_bookings;

-- Verify the plan picks up the index (look for "Index Only Scan"
-- using idx_hotel_bookings_city_created_at in the output):
EXPLAIN ANALYZE
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;