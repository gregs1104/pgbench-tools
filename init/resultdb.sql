BEGIN;

DROP TABLE IF EXISTS testset CASCADE;
CREATE TABLE testset(
  set serial PRIMARY KEY,
  info text
  );

DROP TABLE IF EXISTS tests CASCADE;
CREATE TABLE tests(
  test serial PRIMARY KEY,
  set int NOT NULL REFERENCES testset(set) ON DELETE CASCADE,
  scale int,
  dbsize int8,
  start_time timestamp default now(),
  end_time timestamp default null,
  tps decimal default 0,
  script text,
  clients int,
  workers int,
  trans int,
  avg_latency float,
  max_latency float,
  percentile_90_latency float,
  wal_written numeric,
  cleanup interval default null,
  rate_limit numeric default null
  );

DROP TABLE IF EXISTS timing CASCADE;
-- Staging table, for loading in data from CSV
CREATE TABLE timing(
  ts timestamp,
  filenum int,
  latency numeric(9,3),
  test int NOT NULL REFERENCES tests(test)
  );

CREATE INDEX idx_timing_test on timing(test,ts);

DROP TABLE IF EXISTS test_bgwriter CASCADE;
CREATE TABLE test_bgwriter(
  test int PRIMARY KEY REFERENCES tests(test) ON DELETE CASCADE,
  checkpoints_timed bigint,
  checkpoints_req bigint,
  buffers_checkpoint bigint,
  buffers_clean bigint,
  maxwritten_clean bigint,
  buffers_backend bigint,
  buffers_alloc bigint,
  buffers_backend_fsync bigint,
  max_dirty bigint
);

--
-- Convert hex value to a decimal one.  It's possible to do this using
-- undocumented features of the bit type, such as:
--
--     "SELECT 'xff'::text::bit(8)::int;"
--
-- This function relies on that only to convert single hex digits, meaning
-- it handles abitrarily large numbers too.  The code is inspired by the hex
-- to decimal examples at http://postgres.cz and is not case sensitive.
--
-- Sample tests:
--
-- SELECT hex_to_dec('FF');
-- SELECT hex_to_dec('ffff');
-- SELECT hex_to_dec('FFff');
-- SELECT hex_to_dec('FFFFFFFFFFFFFFFF');
--
CREATE OR REPLACE FUNCTION hex_to_dec (text)
RETURNS numeric AS
$$
DECLARE 
    r numeric;
    i int;
    digit int;
BEGIN
    r := 0;
    FOR i in 1..length($1) LOOP 
        EXECUTE E'SELECT x\''||substring($1 from i for 1)|| E'\'::integer' INTO digit;
        r := r * 16 + digit;
        END LOOP;
    RETURN r;
END
;
$$ LANGUAGE plpgsql IMMUTABLE
;

--
-- Process the output from pg_current_xlog_location() or
-- pg_current_xlog_insert_location() and return a WAL Logical Serial Number
-- from that information.  That represents an always incrementing offset
-- within the WAL stream, proportional to how much data has been written
-- there.  The input will look like '2/13BDE690'.
--
-- Sample use:
--
-- SELECT wal_lsn(pg_current_xlog_location());
-- SELECT wal_lsn(pg_current_xlog_insert_location());
--
-- There's no error checking here.  If you input a hex string without a "/"
-- in it, the function will process it without complaint, returning a large
-- number as if that were the left hand side of a valid pair.
--
CREATE OR REPLACE FUNCTION wal_lsn (text)
RETURNS numeric AS $$
SELECT hex_to_dec(split_part($1,'/',1)) * 16 * 1024 * 1024 * 255
    + hex_to_dec(split_part($1,'/',2));
$$ language sql
;

COMMIT;
