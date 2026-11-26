CREATE EXTENSION ulid;

-- ULID to timestamp conversion
SELECT ('01H55TNAQ96WPSWE6WZRCH9G0C'::ulid)::timestamp;

-- Boundary values
SELECT ('00000000000000000000000000'::ulid)::timestamp AS unix_epoch;
SELECT ('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'::ulid)::timestamp AS max_timestamp;

-- Timestamp to ULID (verify timestamp is preserved)
SELECT (timestamp_to_ulid('2023-07-12 19:53:43.401'::timestamp))::timestamp;

-- Round-trip: timestamp -> ULID -> timestamp (millisecond precision preserved)
SELECT ts::timestamp(3) = (timestamp_to_ulid(ts))::timestamp::timestamp(3) AS roundtrip_preserved
FROM (SELECT '2023-07-12 19:53:43.401'::timestamp AS ts) t;

-- Timezone-aware (timestamptz) casts.
-- The instant a ULID encodes is absolute, so its UTC rendering is the same
-- regardless of the session time zone.
SET TIME ZONE 'America/Sao_Paulo';
SELECT ('01H55TNAQ96WPSWE6WZRCH9G0C'::ulid::timestamptz AT TIME ZONE 'UTC') AS instant_utc;

-- A timestamptz round-trips through a ULID preserving the exact instant, in any
-- session time zone.
SELECT '2023-07-12 19:53:43.401+00'::timestamptz
       = timestamptz_to_ulid('2023-07-12 19:53:43.401+00'::timestamptz)::timestamptz
       AS tstz_roundtrip;

-- now()::ulid works (timestamptz -> ulid) and round-trips to within a millisecond.
SELECT (now() - now()::ulid::timestamptz) < interval '1 second' AS now_roundtrip_close;
RESET TIME ZONE;

-- A ULID holds 48 bits of milliseconds since 1970-01-01 UTC. Timestamps outside
-- that range must be rejected, not silently wrapped to a far-future ULID.
SELECT ('1970-01-01 00:00:00'::timestamp)::ulid::timestamp AS min_timestamp;
SELECT ('10889-08-02 05:31:50.655'::timestamp)::ulid::timestamp AS max_timestamp;
SELECT ('1969-12-31 23:59:59'::timestamp)::ulid;
SELECT ('10889-08-02 05:31:50.656'::timestamp)::ulid;
SELECT ('infinity'::timestamp)::ulid;
SELECT ('-infinity'::timestamp)::ulid;
SELECT timestamptz_to_ulid('1969-12-31 23:59:59+00'::timestamptz);
