CREATE EXTENSION ulid;

-- Output is valid 26-character ULID
SELECT length(gen_ulid()::text) = 26 AS valid_length;

-- Multiple generations produce different values (randomness works)
SELECT gen_ulid() <> gen_ulid() AS unique_values;
