BEGIN;

CREATE EXTENSION ulid;

-- Average time to generate 1.000.000 ULIDs.
WITH RECURSIVE avg_time_calc AS (
  SELECT interval '0' AS total_time, 0 AS iteration_count
  UNION ALL
  SELECT total_time + (clock_timestamp() - statement_timestamp()), iteration_count + 1
  FROM avg_time_calc
  WHERE iteration_count < 1000000
)
SELECT (SELECT total_time FROM avg_time_calc WHERE iteration_count = 1000000) / 1000000 AS avg_time;

-- Time to generate a single ULID.
WITH time_calc AS (
  SELECT clock_timestamp() - statement_timestamp() AS time_taken
)
SELECT time_taken FROM time_calc;

ROLLBACK;
