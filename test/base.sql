BEGIN;

CREATE EXTENSION ulid;

SELECT
  ('01H55TNAQ96WPSWE6WZRCH9G0C' :: ulid) :: timestamp;

SELECT
  '01H539HMN700009Y99Q81VWK04' :: ulid = '01H539HMN700009Y99Q81VWK04' :: ulid;

SELECT
  gen_ulid();

SELECT
  ulid_to_timestamp(gen_ulid());

SELECT
  (gen_ulid() :: timestamp);

SELECT
  gen_ulid(),
  *
FROM
  generate_series(1, 10)
ORDER BY
  gen_ulid;

CREATE TABLE ulids (id ulid);

INSERT INTO
  ulids
VALUES
  ('7ZZZZZZZZZZZZZZZZZZZZZZZZZ'),
  ('01H55TNAQ96WPSWE6WZRCH9G0C');

SELECT
  id
FROM
  ulids;

EXPLAIN ANALYZE
INSERT INTO
  ulids
SELECT
  gen_ulid()
FROM
  generate_series(1, 100000) s(i);

ROLLBACK;
