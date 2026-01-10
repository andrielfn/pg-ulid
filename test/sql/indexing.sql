CREATE EXTENSION ulid;

-- B-tree index (default for PRIMARY KEY)
CREATE TABLE indexed_ulids (id ulid PRIMARY KEY);

INSERT INTO indexed_ulids VALUES
  ('01H539HMN700009Y99Q81VWK04'),
  ('01H539HMN700009Y99Q81VWK05'),
  ('01H539HMN700009Y99Q81VWK06');

-- B-tree index used for equality lookup
EXPLAIN (COSTS OFF) SELECT * FROM indexed_ulids WHERE id = '01H539HMN700009Y99Q81VWK04'::ulid;

-- B-tree index used for range queries
EXPLAIN (COSTS OFF) SELECT * FROM indexed_ulids WHERE id > '01H539HMN700009Y99Q81VWK04'::ulid;

-- Hash index support
CREATE INDEX idx_hash ON indexed_ulids USING hash (id);

-- Verify hash index can be used
EXPLAIN (COSTS OFF) SELECT * FROM indexed_ulids WHERE id = '01H539HMN700009Y99Q81VWK04'::ulid;
