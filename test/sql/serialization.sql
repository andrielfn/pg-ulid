CREATE EXTENSION ulid;

--
-- Binary send (ulid_send): produces the raw 16 big-endian bytes.
--
SELECT ulid_send('01H539HMN700009Y99Q81VWK04'::ulid) AS send_bytes;
SELECT length(ulid_send('01H539HMN700009Y99Q81VWK04'::ulid)) AS send_length;

-- send must agree with the ::bytea cast (both are the raw representation)
SELECT ulid_send('01H539HMN700009Y99Q81VWK04'::ulid)
       = '01H539HMN700009Y99Q81VWK04'::ulid::bytea AS send_matches_bytea;

--
-- Binary send + receive round-trip via COPY (FORMAT binary). COPY TO exercises
-- ulid_send; COPY FROM exercises ulid_recv. Client-side \copy avoids needing
-- server-side file permissions.
--
CREATE TABLE sr_src (k int, id ulid);
INSERT INTO sr_src VALUES
  (1, '01H539HMN700009Y99Q81VWK04'),
  (2, '00000000000000000000000000'),
  (3, '7ZZZZZZZZZZZZZZZZZZZZZZZZZ'),
  (4, gen_ulid());
CREATE TABLE sr_dst (k int, id ulid);

\copy sr_src TO '/tmp/ulid_sendrecv.bin' (FORMAT binary)
\copy sr_dst FROM '/tmp/ulid_sendrecv.bin' (FORMAT binary)

-- Every value must survive the binary round-trip unchanged.
SELECT count(*) AS roundtrip_rows, bool_and(s.id = d.id) AS sendrecv_roundtrip
FROM sr_src s JOIN sr_dst d USING (k);

DROP TABLE sr_src;
DROP TABLE sr_dst;

--
-- Hashing (ulid_hash).
--
-- Deterministic: same value always hashes the same.
SELECT ulid_hash('01H539HMN700009Y99Q81VWK04'::ulid)
       = ulid_hash('01H539HMN700009Y99Q81VWK04'::ulid) AS hash_deterministic;

-- Hash-opclass invariant: equal ULIDs hash equal (here via case-insensitive
-- input that decodes to the same value).
SELECT ulid_hash('01H539HMN700009Y99Q81VWK04'::ulid)
       = ulid_hash('01h539hmn700009y99q81vwk04'::ulid) AS equal_values_hash_equal;

-- Functional: a hash index actually returns the right row via the hash path.
CREATE TABLE hashed (id ulid);
INSERT INTO hashed SELECT gen_ulid() FROM generate_series(1, 1000);
INSERT INTO hashed VALUES ('01H539HMN700009Y99Q81VWK04');
CREATE INDEX hashed_idx ON hashed USING hash (id);

-- Force the index path so the lookup is answered through the hash index (and
-- thus ulid_hash); a wrong hash would return the wrong count.
SET enable_seqscan = off;
SELECT count(*) AS hash_lookup_hits FROM hashed WHERE id = '01H539HMN700009Y99Q81VWK04'::ulid;
RESET enable_seqscan;

DROP TABLE hashed;
