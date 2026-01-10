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
