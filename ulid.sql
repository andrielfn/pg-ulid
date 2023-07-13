CREATE TYPE ulid;

--
--  Generate and cast functions.
--
CREATE FUNCTION gen_ulid () RETURNS ulid AS 'ulid' LANGUAGE C STRICT PARALLEL SAFE;

CREATE FUNCTION ulid_to_timestamp (ulid) RETURNS TIMESTAMP AS 'ulid' LANGUAGE C IMMUTABLE STRICT;

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
