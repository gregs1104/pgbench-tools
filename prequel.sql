ALTER TABLE tests ADD COLUMN server text;
ALTER TABLE test_bgwriter ADD COLUMN server text;
ALTER TABLE test_stat_database ADD COLUMN server text;
ALTER TABLE test_statio ADD COLUMN server text;
ALTER TABLE timing ADD COLUMN server text;
ALTER TABLE testset ADD COLUMN server text;

ALTER TABLE test_bgwriter DROP CONSTRAINT test_bgwriter_test_fkey;
ALTER TABLE test_stat_database DROP CONSTRAINT test_stat_database_test_fkey;
ALTER TABLE test_statio DROP CONSTRAINT test_statio_test_fkey;
ALTER TABLE timing DROP CONSTRAINT timing_test_fkey;
ALTER TABLE tests DROP CONSTRAINT tests_pkey;
ALTER TABLE tests DROP CONSTRAINT tests_set_fkey;
ALTER TABLE test_bgwriter DROP CONSTRAINT test_bgwriter_pkey;
ALTER TABLE test_stat_database DROP CONSTRAINT test_stat_database_pkey;
ALTER TABLE testset DROP CONSTRAINT testset_pkey;

CREATE UNIQUE INDEX idx_server_set on testset(server,set);
ALTER TABLE testset ADD UNIQUE USING INDEX idx_server_set;

CREATE UNIQUE INDEX idx_server_test on tests(server,test);
ALTER TABLE tests ADD UNIQUE USING INDEX idx_server_test;

CREATE UNIQUE INDEX idx_server_test_2 on test_bgwriter(server,test);
ALTER TABLE test_bgwriter ADD UNIQUE USING INDEX idx_server_test_2;

CREATE UNIQUE INDEX idx_server_test_3 on test_stat_database(server,test);
ALTER TABLE test_stat_database ADD UNIQUE USING INDEX idx_server_test_3;

CREATE INDEX idx_test on test_statio(server,test);

DROP VIEW test_stats;
CREATE VIEW test_stats AS
SELECT
  set, tests.server,UPPER(script) AS script,scale,clients,tests.test,
  round(tps) as tps, max_latency,
  round(blks_hit           * 8192 / extract(epoch FROM (collected - tests.start_time)))::bigint AS hit_Bps,
  round(blks_read          * 8192 / extract(epoch FROM (collected - tests.start_time)))::bigint AS read_Bps,
  round(buffers_checkpoint * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS check_Bps,
  round(buffers_clean      * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS clean_Bps,
  round(buffers_backend    * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS backend_Bps,
  round(wal_written / extract(epoch from (tests.end_time - tests.start_time)))::bigint AS wal_written_Bps,
  max_dirty
FROM test_bgwriter
  RIGHT JOIN tests ON tests.test=test_bgwriter.test
  RIGHT JOIN test_stat_database ON tests.test=test_stat_database.test;
