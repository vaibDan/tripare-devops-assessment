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
    -- Spread created_at over the last 60 days so some rows fall inside
    -- (and some outside) the "last 30 days" window used in the target query.
    now() - (floor(random() * 60) || ' days')::interval
FROM generate_series(1, 150) AS s
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

-- Quick sanity check counts
SELECT 'hotel_bookings' AS table_name, COUNT(*) FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events;