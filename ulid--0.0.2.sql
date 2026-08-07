CREATE TYPE ulid;

--
--  Generate and cast functions.
--
CREATE FUNCTION gen_ulid () RETURNS ulid AS 'ulid' LANGUAGE C STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_to_timestamp (ulid) RETURNS TIMESTAMP AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

-- VOLATILE: this draws fresh randomness, so it must not be constant-folded
-- (otherwise a constant input would yield the same ULID for every row).
-- VOLATILE + PARALLEL SAFE is not a contradiction: volatility governs constant
-- folding, parallel safety governs what may run in a worker. This draws its own
-- entropy and touches no shared state, exactly like core Postgres's random().
CREATE FUNCTION timestamp_to_ulid (TIMESTAMP) RETURNS ulid AS 'ulid' LANGUAGE C VOLATILE STRICT PARALLEL SAFE;


--
--  Input and output functions.
--
CREATE FUNCTION ulid_in (cstring) RETURNS ulid AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_out (ulid) RETURNS cstring AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_recv (internal) RETURNS ulid AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_send (ulid) RETURNS bytea AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
--  The type itself.
--
CREATE TYPE ulid (
    INPUT = ulid_in,
    OUTPUT = ulid_out,
    INTERNALLENGTH = 16,
    -- char alignment (like uuid): a 16-byte pass-by-reference value never needs
    -- alignment padding, so this avoids up to 3 wasted bytes per row and makes
    -- ulid byte-for-byte identical in storage to uuid.
    ALIGNMENT = char,
    SEND = ulid_send,
    RECEIVE = ulid_recv
);

--
--  Implicit and assignment type casts.
--
CREATE CAST(ulid AS text)
WITH
    INOUT AS IMPLICIT;

CREATE CAST(text AS ulid)
WITH
    INOUT AS IMPLICIT;

CREATE CAST(ulid AS TIMESTAMP)
WITH
    FUNCTION ulid_to_timestamp (ulid) AS IMPLICIT;

CREATE CAST (timestamp AS ulid)
WITH
    FUNCTION timestamp_to_ulid(timestamp) AS IMPLICIT;

-- Timezone-aware variants (recommended). A ULID encodes a UTC instant, so the
-- natural Postgres type is timestamptz. The underlying C already computes a true
-- UTC instant, so these casts respect the session time zone and round-trip the
-- instant exactly (and they make now()::ulid work). The plain `timestamp` casts
-- above are kept for backward compatibility and treat values as UTC wall-clock.
CREATE FUNCTION ulid_to_timestamptz (ulid) RETURNS timestamptz AS 'ulid', 'ulid_to_timestamp' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION timestamptz_to_ulid (timestamptz) RETURNS ulid AS 'ulid', 'timestamp_to_ulid' LANGUAGE C VOLATILE STRICT PARALLEL SAFE;

CREATE CAST (ulid AS timestamptz)
WITH
    FUNCTION ulid_to_timestamptz (ulid) AS ASSIGNMENT;

CREATE CAST (timestamptz AS ulid)
WITH
    FUNCTION timestamptz_to_ulid (timestamptz) AS ASSIGNMENT;

-- ulid and uuid have identical on-disk representation (16-byte, pass-by-ref,
-- char-aligned, plain storage), so these casts are binary (WITHOUT FUNCTION):
-- no per-value work, and ALTER COLUMN ... TYPE between uuid and ulid becomes a
-- metadata-only catalog change with no table rewrite.
CREATE CAST (ulid AS uuid) WITHOUT FUNCTION AS ASSIGNMENT;

CREATE CAST (uuid AS ulid) WITHOUT FUNCTION AS ASSIGNMENT;

-- Raw 16-byte access. bytea is an untyped blob, so these casts are explicit
-- only (no implicit/assignment coercion) to avoid surprising conversions; the
-- bytea -> ulid direction validates the length is exactly 16 bytes.
CREATE FUNCTION ulid_to_bytea (ulid) RETURNS bytea AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION bytea_to_ulid (bytea) RETURNS ulid AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (ulid AS bytea)
WITH
    FUNCTION ulid_to_bytea (ulid);

CREATE CAST (bytea AS ulid)
WITH
    FUNCTION bytea_to_ulid (bytea);


--
-- Operator Functions.
--
CREATE FUNCTION ulid_eq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_neq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_leq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_lt (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_geq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_gt (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

--
-- Operators.
--
CREATE OPERATOR = (
    PROCEDURE = ulid_eq,
    LEFTARG = ulid,
    RIGHTARG = ulid,
    COMMUTATOR = =,
    NEGATOR = <>,
    RESTRICT = eqsel,
    JOIN = eqjoinsel,
    MERGES,
    HASHES
);

CREATE OPERATOR <> (
    PROCEDURE = ulid_neq,
    LEFTARG = ulid,
    RIGHTARG = ulid,
    COMMUTATOR = <>,
    NEGATOR = =,
    RESTRICT = neqsel,
    JOIN = neqjoinsel
);

CREATE OPERATOR < (
    PROCEDURE = ulid_lt,
    LEFTARG = ulid,
    RIGHTARG = ulid,
    COMMUTATOR = >,
    NEGATOR = >=,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR > (
    PROCEDURE = ulid_gt,
    LEFTARG = ulid,
    RIGHTARG = ulid,
    COMMUTATOR = <,
    NEGATOR = <=,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

CREATE OPERATOR <= (
    PROCEDURE = ulid_leq,
    LEFTARG = ulid,
    RIGHTARG = ulid,
    COMMUTATOR = >=,
    NEGATOR = >,
    RESTRICT = scalarltsel,
    JOIN = scalarltjoinsel
);

CREATE OPERATOR >= (
    PROCEDURE = ulid_geq,
    LEFTARG = ulid,
    RIGHTARG = ulid,
    COMMUTATOR = <=,
    NEGATOR = <,
    RESTRICT = scalargtsel,
    JOIN = scalargtjoinsel
);

--
-- Support functions for indexing.
--
CREATE FUNCTION ulid_cmp (ulid, ulid) RETURNS INT AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS btree_ulid_ops DEFAULT FOR TYPE ulid USING btree AS OPERATOR 1 <,
OPERATOR 2 <=,
OPERATOR 3 =,
OPERATOR 4 >=,
OPERATOR 5 >,
FUNCTION 1 ulid_cmp (ulid, ulid);

CREATE FUNCTION ulid_hash (ulid) RETURNS int4 AS 'ulid' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR CLASS ulid_ops DEFAULT FOR TYPE ulid USING hash AS OPERATOR 1 = (ulid, ulid),
FUNCTION 1 ulid_hash (ulid);
