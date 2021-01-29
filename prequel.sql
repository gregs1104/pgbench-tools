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

ALTER TABLE tests ADD COLUMN server_version text default version();

CREATE TABLE server(
  server text NOT NULL PRIMARY KEY,
  server_info text,
  server_cpu text,
  server_mem text,
  server_disk text,
  server_num_proc int,
  server_mem_gb int,
  server_disk_gb int,
  server_details jsonb
  );

DROP VIEW IF EXISTS test_stats;
CREATE VIEW test_stats AS
SELECT
  tests.set, testset.info, tests.server,script,scale,clients,tests.test,
  round(dbsize / (1024 * 1024)) as dbsize_mb,
  round(tps) as tps, max_latency,
  round(blks_hit           * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS hit_Bps,
  round(blks_read          * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS read_Bps,
  round(buffers_checkpoint * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS check_Bps,
  round(buffers_clean      * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS clean_Bps,
  round(buffers_backend    * 8192 / extract(epoch FROM (tests.end_time - tests.start_time)))::bigint AS backend_Bps,
  round(wal_written / extract(epoch from (tests.end_time - tests.start_time)))::bigint AS wal_written_Bps,
  max_dirty,
  server_version,
  server_info,
  server_num_proc,
  server_mem_gb,
  server_disk_gb,
  server_details
FROM test_bgwriter
  RIGHT JOIN tests ON tests.test=test_bgwriter.test AND tests.server=test_bgwriter.server
  RIGHT JOIN test_stat_database ON tests.test=test_stat_database.test AND tests.server=test_stat_database.server
  RIGHT JOIN testset ON testset.set=tests.set and tests.server=test_bgwriter.server
  FULL OUTER JOIN server on tests.server=server.server
ORDER BY server,set,info,script,scale,clients,tests.test
;

CREATE TABLE tmp_metric_import (
    collected timestamp,
    value float,
    metric text NOT NULL
);

CREATE TABLE test_metrics_data (
    collected TIMESTAMP,
    value float,
    metric text NOT NULL,
    test integer NOT NULL,
    server text NOT NULL
);

CREATE INDEX idx_test_metrics_test on test_metrics_data(server,test);

DROP VIEW IF EXISTS test_metrics;
CREATE VIEW test_metrics AS
  SELECT tests.test,tests.server,script,scale,clients,
    tps,dbsize,wal_written,collected,value,metric
  FROM test_metrics_data,tests
  WHERE tests.test=test_metrics_data.test AND
    tests.server=test_metrics_data.server
;

DROP VIEW IF EXISTS test_metric_summary;
CREATE VIEW test_metric_summary AS
  WITH ts AS (
    SELECT test_stats.info,test_stats.server,test_stats.set,
      test_stats.script,test_stats.scale,test_stats.clients,test_stats.test,test_stats.tps,
      hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
      server_num_proc,server_mem_gb,server_disk_gb
    FROM test_stats
    ORDER BY test_stats.server,test_stats.set,
      test_stats.script,test_stats.scale,test_stats.clients,test_stats.test)
  SELECT ts.server,ts.set,ts.script,ts.scale,ts.clients,ts.test,ts.tps,
    hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
    server_num_proc,server_mem_gb,server_disk_gb,
    round(100.0 * dbsize_mb / 1024 / server_mem_gb) AS ram_pct,
    metric,min(value) as min,round(avg(value)) as avg,max(value) as max
  FROM ts
  JOIN test_metrics_data ON ts.test=test_metrics_data.test AND ts.server=test_metrics_data.server
  GROUP BY test_metrics_data.metric,ts.server,ts.set,ts.info,ts.script,ts.scale,ts.clients,ts.test,ts.tps,
    hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
    server_num_proc,server_mem_gb,server_disk_gb
  ORDER BY test_metrics_data.metric,ts.server,ts.set,ts.info,ts.script,ts.scale,ts.clients,ts.test,ts.tps,
    hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
    server_num_proc,server_mem_gb,server_disk_gb;

CREATE TABLE test_settings (
    server text,
    test integer,
    name text,
    setting text,
    unit text,
    source text,
    boot_val text,
    value text,
    numeric_value numeric,
    numeric_unit text
);

CREATE TABLE test_statements (
    server text,
    test text,
    queryid bigint,
    query text,
    plans bigint,
    total_plan_time double precision,
    min_plan_time double precision,
    max_plan_time double precision,
    mean_plan_time double precision,
    stddev_plan_time double precision,
    calls bigint,
    total_exec_time double precision,
    min_exec_time double precision,
    max_exec_time double precision,
    mean_exec_time double precision,
    stddev_exec_time double precision,
    rows bigint,
    shared_blks_hit bigint,
    shared_blks_read bigint,
    shared_blks_dirtied bigint,
    shared_blks_written bigint,
    local_blks_hit bigint,
    local_blks_read bigint,
    local_blks_dirtied bigint,
    local_blks_written bigint,
    temp_blks_read bigint,
    temp_blks_written bigint,
    blk_read_time double precision,
    blk_write_time double precision,
    wal_records bigint,
    wal_fpi bigint,
    wal_bytes numeric
);
