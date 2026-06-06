CREATE EXTENSION ulid;

-- Output is valid 26-character ULID
SELECT length(gen_ulid()::text) = 26 AS valid_length;

-- Multiple generations produce different values (randomness works)
SELECT gen_ulid() <> gen_ulid() AS unique_values;

-- Monotonicity: a batch generated in one session is strictly increasing, even
-- for IDs minted within the same millisecond (the random part is incremented).
CREATE TABLE gen_mono (seq serial, id ulid);
INSERT INTO gen_mono (id) SELECT gen_ulid() FROM generate_series(1, 50000);

SELECT bool_and(id > prev) AS strictly_increasing
FROM (SELECT id, lag(id) OVER (ORDER BY seq) AS prev FROM gen_mono) t
WHERE prev IS NOT NULL;

-- And every generated value is distinct.
SELECT count(DISTINCT id) = count(*) AS all_distinct FROM gen_mono;

DROP TABLE gen_mono;
