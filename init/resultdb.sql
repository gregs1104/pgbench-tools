BEGIN;

DROP TABLE IF EXISTS testset CASCADE;
CREATE TABLE testset(
  server text NOT NULL,
  set serial NOT NULL,
  info text
  );

DROP TABLE IF EXISTS tests CASCADE;
CREATE TABLE tests(
  server text NOT NULL,
  test serial,
  set int NOT NULL,
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
  rate_limit numeric default null,
  start_latency timestamp default null,
  end_latency timestamp default null,
  trans_latency int default null,
  server_version text default version()
  );

DROP TABLE IF EXISTS timing;
-- Staging table, for loading in data from CSV
CREATE TABLE timing(
  ts timestamp,
  filenum int, 
  latency numeric(9,3),
  test int NOT NULL,
  server text
  );

CREATE INDEX idx_timing_test on timing(test,ts);
CREATE INDEX idx_test_latency ON timing (test,latency);

DROP TABLE IF EXISTS test_bgwriter;
CREATE TABLE test_bgwriter(
  test int NOT NULL,
  checkpoints_timed bigint,
  checkpoints_req bigint,
  buffers_checkpoint bigint,
  buffers_clean bigint,
  maxwritten_clean bigint,
  buffers_backend bigint,
  buffers_alloc bigint,
  buffers_backend_fsync bigint,
  max_dirty bigint,
  server text NOT NULL
);

DROP TABLE IF EXISTS test_stat_database;
CREATE TABLE test_stat_database(
  test int NOT NULL,
  collected timestamp,
  last_reset timestamp,
  numbackends int,
  xact_commit bigint, xact_rollback bigint,
  blks_read bigint, blks_hit bigint,
  tup_returned bigint, tup_fetched bigint, tup_inserted bigint,
  tup_updated bigint, tup_deleted bigint,
  conflicts bigint,
  temp_files bigint, temp_bytes bigint,
  deadlocks bigint,
  blk_read_time double precision, blk_write_time double precision,
  server text NOT NULL
  );

DROP TABLE IF EXISTS test_statio;
CREATE TABLE test_statio(
  test int NOT NULL,
  collected timestamp,
  nspname name,
  tablename name,
  indexname name,
  size bigint,
  rel_blks_read bigint,
  rel_blks_hit bigint,
  server text NOT NULL
);

DROP TABLE IF EXISTS buckets;
CREATE TABLE buckets (
    bucket_left numeric,
    bucket_right numeric,
    offset_left numeric,
    offset_right numeric,
    latency_left numeric,
    latency_right numeric
);

CREATE UNIQUE INDEX idx_server_set on testset(server,set);
ALTER TABLE testset ADD UNIQUE USING INDEX idx_server_set;

CREATE UNIQUE INDEX idx_server_test on tests(server,test);
ALTER TABLE tests ADD UNIQUE USING INDEX idx_server_test;

CREATE UNIQUE INDEX idx_server_test_2 on test_bgwriter(server,test);
ALTER TABLE test_bgwriter ADD UNIQUE USING INDEX idx_server_test_2;

CREATE UNIQUE INDEX idx_server_test_3 on test_stat_database(server,test);
ALTER TABLE test_stat_database ADD UNIQUE USING INDEX idx_server_test_3;

CREATE INDEX idx_test on test_statio(server,test);

ALTER TABLE test_bgwriter ADD CONSTRAINT testfk FOREIGN KEY (server,test) REFERENCES tests (server,test) MATCH SIMPLE;
ALTER TABLE test_stat_database ADD CONSTRAINT testfk FOREIGN KEY (server,test) REFERENCES tests (server,test) MATCH SIMPLE;
ALTER TABLE test_statio ADD CONSTRAINT testfk FOREIGN KEY (server,test) REFERENCES tests (server,test) MATCH SIMPLE;
ALTER TABLE timing ADD CONSTRAINT testfk FOREIGN KEY (server,test) REFERENCES tests (server,test) MATCH SIMPLE;

DROP VIEW test_stats;
CREATE VIEW test_stats AS
SELECT
  tests.set, testset.info, tests.server,script,scale,clients,tests.test,
  round(tps) as tps, max_latency,
  round(blks_hit           * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS hit_Bps,
  round(blks_read          * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS read_Bps,
  round(buffers_checkpoint * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS check_Bps,
  round(buffers_clean      * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS clean_Bps,
  round(buffers_backend    * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS backend_Bps,
  round(wal_written / extract(epoch from (tests.end_time - tests.start_time)))::bigint AS wal_written_Bps,
  max_dirty,
  round(dbsize / (1024 * 1024)) as dbsize_mb,server_version
FROM test_bgwriter
  RIGHT JOIN tests ON tests.test=test_bgwriter.test AND tests.server=test_bgwriter.server
  RIGHT JOIN test_stat_database ON tests.test=test_stat_database.test AND tests.server=test_stat_database.server
  RIGHT JOIN testset ON testset.set=test.set and tests.server=test_bgwriter.server
;

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
