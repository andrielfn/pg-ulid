-- 0.0.1 -> 0.0.2: mark the remaining functions PARALLEL SAFE.
--
-- 0.0.1 shipped only 5 of 19 functions marked PARALLEL SAFE. The omission is
-- visible in that release's own script: ulid_to_timestamp and ulid_to_timestamptz
-- bind the SAME C symbol, yet only the latter carried the marking.
--
-- A single parallel-unsafe function anywhere in a plan bars the WHOLE plan from
-- parallel execution. Because ulid_eq backs the `=` operator, every join on a ulid
-- column -- i.e. every foreign-key join in a ulid-keyed schema -- silently ran
-- single-threaded no matter how many cores were available. Observed on a 16-vCPU
-- box: a 33.6M-row join fell from 24.5s to 8.2s once these markings were corrected,
-- switching from a serial Hash Join to a Parallel Hash Join.
--
-- All of these are safe to mark. Every one is IMMUTABLE except the two generators
-- below, which are VOLATILE only because they draw fresh randomness (volatility
-- governs constant folding; parallel safety governs what may run in a worker --
-- core Postgres's own random() is likewise VOLATILE + PARALLEL SAFE). None writes
-- to the database or reads state that differs across workers: the sole
-- process-local state in the extension backs gen_ulid's monotonic path, and
-- gen_ulid was already PARALLEL SAFE in 0.0.1.

-- Casts to/from timestamp.
ALTER FUNCTION ulid_to_timestamp(ulid) PARALLEL SAFE;
ALTER FUNCTION timestamp_to_ulid(timestamp) PARALLEL SAFE;
ALTER FUNCTION timestamptz_to_ulid(timestamptz) PARALLEL SAFE;

-- Type input/output and binary send/recv.
ALTER FUNCTION ulid_in(cstring) PARALLEL SAFE;
ALTER FUNCTION ulid_out(ulid) PARALLEL SAFE;
ALTER FUNCTION ulid_recv(internal) PARALLEL SAFE;
ALTER FUNCTION ulid_send(ulid) PARALLEL SAFE;

-- Comparison operators -- the ones that actually gate parallel plans.
ALTER FUNCTION ulid_eq(ulid, ulid) PARALLEL SAFE;
ALTER FUNCTION ulid_neq(ulid, ulid) PARALLEL SAFE;
ALTER FUNCTION ulid_lt(ulid, ulid) PARALLEL SAFE;
ALTER FUNCTION ulid_leq(ulid, ulid) PARALLEL SAFE;
ALTER FUNCTION ulid_gt(ulid, ulid) PARALLEL SAFE;
ALTER FUNCTION ulid_geq(ulid, ulid) PARALLEL SAFE;

-- B-tree support function.
ALTER FUNCTION ulid_cmp(ulid, ulid) PARALLEL SAFE;
