-- Same structure as the original 150-row seed, scaled up to 50,000 bookings
-- so the query planner has enough data to prefer the index over a full
-- table scan. At 150 rows a seq scan is genuinely cheaper (see README) —
-- this is the "at realistic scale" proof.

TRUNCATE booking_events, hotel_bookings RESTART IDENTITY CASCADE;

INSERT INTO hotel_bookings (id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at)
SELECT
    gen_random_uuid(),
    orgs[1 + floor(random() * array_length(orgs, 1))::int],
    'HTL' || (floor(random() * 500) + 1)::int,
    cities[1 + floor(random() * array_length(cities, 1))::int],
    ci,
    ci + (floor(random() * 5) + 1)::int,
    round((random() * 20000 + 1000)::numeric, 2),
    statuses[1 + floor(random() * array_length(statuses, 1))::int],
    -- Spread over the last 90 days so a meaningful chunk falls inside
    -- (and outside) the 30-day window used by the target query.
    now() - (floor(random() * 90) || ' days')::interval
FROM generate_series(1, 50000) AS s
CROSS JOIN LATERAL (
    SELECT
        ARRAY[
            'a1111111-1111-1111-1111-111111111111',
            'a2222222-2222-2222-2222-222222222222',
            'a3333333-3333-3333-3333-333333333333',
            'a4444444-4444-4444-4444-444444444444'
        ]::uuid[] AS orgs,
        ARRAY['delhi', 'mumbai', 'bangalore', 'pune', 'chennai'] AS cities,
        ARRAY['pending', 'confirmed', 'cancelled', 'completed'] AS statuses,
        CURRENT_DATE - (floor(random() * 90))::int AS ci
) AS gen;

-- booking_events for roughly half the bookings, 1-3 events each
INSERT INTO booking_events (booking_id, event_type, payload, created_at)
SELECT
    b.id,
    (ARRAY['booking_created', 'payment_received', 'status_changed', 'booking_cancelled'])
        [1 + floor(random() * 4)::int],
    jsonb_build_object(
        'source', 'seed-script',
        'random_ref', floor(random() * 1000)
    ),
    b.created_at + (floor(random() * 48) || ' hours')::interval
FROM hotel_bookings b
CROSS JOIN generate_series(1, (1 + floor(random() * 3))::int)
WHERE random() < 0.5;

-- Sanity check counts + how many rows actually match the target query's filter
SELECT 'hotel_bookings' AS table_name, COUNT(*) FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events
UNION ALL
SELECT 'matches target query filter (delhi, last 30 days)',
       COUNT(*) FROM hotel_bookings
       WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days';