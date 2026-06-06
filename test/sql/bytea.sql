CREATE EXTENSION ulid;

-- ulid -> bytea is the raw 16-byte big-endian value (matches the uuid bytes)
SELECT '01H539HMN700009Y99Q81VWK04'::ulid::bytea AS ulid_bytes;
SELECT length('01H539HMN700009Y99Q81VWK04'::ulid::bytea) AS byte_length;

-- Round-trip: ulid -> bytea -> ulid is identity
SELECT '01H539HMN700009Y99Q81VWK04'::ulid::bytea::ulid AS ulid_roundtrip;

-- Round-trip: bytea -> ulid -> bytea is identity
SELECT '\x01894698d2a7000004f929ba03be4c04'::bytea::ulid::bytea
       = '\x01894698d2a7000004f929ba03be4c04'::bytea AS bytea_roundtrip;

-- A generated ULID round-trips through bytea
WITH g AS (SELECT gen_ulid() AS u)
SELECT u::bytea::ulid = u AS gen_roundtrip FROM g;

-- Wrong length is rejected (too short and too long)
SELECT '\xdeadbeef'::bytea::ulid;
SELECT '\x01894698d2a7000004f929ba03be4c0400'::bytea::ulid;
