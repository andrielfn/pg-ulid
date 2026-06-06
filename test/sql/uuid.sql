CREATE EXTENSION ulid;

-- Known vector: ulid -> uuid (same 16 bytes, big-endian)
SELECT '01H539HMN700009Y99Q81VWK04'::ulid::uuid AS ulid_to_uuid;

-- Known vector: uuid -> ulid
SELECT '01894698-d2a7-0000-04f9-29ba03be4c04'::uuid::ulid AS uuid_to_ulid;

-- Boundary values round-trip exactly
SELECT '00000000000000000000000000'::ulid::uuid AS zero_ulid;
SELECT '7ZZZZZZZZZZZZZZZZZZZZZZZZZ'::ulid::uuid AS max_ulid;

-- Round-trip: ulid -> uuid -> ulid is identity
WITH g AS (SELECT gen_ulid() AS u)
SELECT u::uuid::ulid = u AS ulid_uuid_roundtrip FROM g;

-- Round-trip: uuid -> ulid -> uuid is identity
WITH g AS (SELECT 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid AS u)
SELECT u::ulid::uuid = u AS uuid_ulid_roundtrip FROM g;

-- ASSIGNMENT cast: ulid value flows into a uuid column without explicit cast
CREATE TABLE uuid_col (id uuid);
INSERT INTO uuid_col VALUES ('01H539HMN700009Y99Q81VWK04'::ulid);
SELECT id AS inserted_uuid FROM uuid_col;

-- ASSIGNMENT cast: uuid value flows into a ulid column without explicit cast
CREATE TABLE ulid_col (id ulid);
INSERT INTO ulid_col VALUES ('01894698-d2a7-0000-04f9-29ba03be4c04'::uuid);
SELECT id AS inserted_ulid FROM ulid_col;

-- Ordering is preserved across the cast (byte order is identical)
SELECT ('00000000000000000000000000'::ulid::uuid < '7ZZZZZZZZZZZZZZZZZZZZZZZZZ'::ulid::uuid) AS order_preserved;

DROP TABLE uuid_col;
DROP TABLE ulid_col;

-- Binary coercibility: uuid and ulid share an identical on-disk representation,
-- so ALTER COLUMN ... TYPE is a metadata-only change (same relfilenode = no
-- table rewrite), and the stored bytes survive unchanged.
CREATE TABLE migrate_me (id uuid);
INSERT INTO migrate_me VALUES ('01894698-d2a7-0000-04f9-29ba03be4c04');
SELECT pg_relation_filenode('migrate_me') AS before_filenode \gset
ALTER TABLE migrate_me ALTER COLUMN id TYPE ulid;
SELECT pg_relation_filenode('migrate_me') = :before_filenode AS no_table_rewrite;
SELECT id AS migrated_value FROM migrate_me;
DROP TABLE migrate_me;
