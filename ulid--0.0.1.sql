CREATE TYPE ulid;

--
--  Generate and cast functions.
--
CREATE FUNCTION gen_ulid () RETURNS ulid AS 'ulid' LANGUAGE C STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_to_timestamp (ulid) RETURNS TIMESTAMP AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

-- VOLATILE: this draws fresh randomness, so it must not be constant-folded
-- (otherwise a constant input would yield the same ULID for every row).
CREATE FUNCTION timestamp_to_ulid (TIMESTAMP) RETURNS ulid AS 'ulid' LANGUAGE C VOLATILE STRICT;


--
--  Input and output functions.
--
CREATE FUNCTION ulid_in (cstring) RETURNS ulid AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_out (ulid) RETURNS cstring AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_recv (internal) RETURNS ulid AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_send (ulid) RETURNS bytea AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

--
--  The type itself.
--
CREATE TYPE ulid (
    INPUT = ulid_in,
    OUTPUT = ulid_out,
    INTERNALLENGTH = 16,
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

CREATE FUNCTION timestamptz_to_ulid (timestamptz) RETURNS ulid AS 'ulid', 'timestamp_to_ulid' LANGUAGE C VOLATILE STRICT;

CREATE CAST (ulid AS timestamptz)
WITH
    FUNCTION ulid_to_timestamptz (ulid) AS ASSIGNMENT;

CREATE CAST (timestamptz AS ulid)
WITH
    FUNCTION timestamptz_to_ulid (timestamptz) AS ASSIGNMENT;

CREATE FUNCTION ulid_to_uuid (ulid) RETURNS uuid AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION uuid_to_ulid (uuid) RETURNS ulid AS 'ulid' LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE CAST (ulid AS uuid)
WITH
    FUNCTION ulid_to_uuid (ulid) AS ASSIGNMENT;

CREATE CAST (uuid AS ulid)
WITH
    FUNCTION uuid_to_ulid (uuid) AS ASSIGNMENT;


--
-- Operator Functions.
--
CREATE FUNCTION ulid_eq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_neq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_leq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_lt (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_geq (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION ulid_gt (ulid, ulid) RETURNS BOOLEAN AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

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
CREATE FUNCTION ulid_cmp (ulid, ulid) RETURNS INT AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS btree_ulid_ops DEFAULT FOR TYPE ulid USING btree AS OPERATOR 1 <,
OPERATOR 2 <=,
OPERATOR 3 =,
OPERATOR 4 >=,
OPERATOR 5 >,
FUNCTION 1 ulid_cmp (ulid, ulid);

CREATE FUNCTION ulid_hash (ulid) RETURNS int4 AS 'ulid' LANGUAGE C STRICT IMMUTABLE PARALLEL SAFE;

CREATE OPERATOR CLASS ulid_ops DEFAULT FOR TYPE ulid USING hash AS OPERATOR 1 = (ulid, ulid),
FUNCTION 1 ulid_hash (ulid);
