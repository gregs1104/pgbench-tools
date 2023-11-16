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


ALTER TABLE testset ADD COLUMN category text;
ALTER TABLE timing ADD COLUMN schedule_lag numeric;
ALTER TABLE tests ADD COLUMN client_limit numeric;
ALTER TABLE tests ADD COLUMN multi numeric;

DROP VIEW read_io_summary;
CREATE VIEW read_io_summary AS
SELECT
testset.info,
server_num_proc,server_mem_gb,server_disk_gb,
test_metric_summary.server,test_metric_summary.set,
script,scale,clients,multi,test,tps,
metric,round(min) AS read_min,round(avg) AS read_avg,round(max) AS read_max,
round(hit_bps / 1024 / 1024) AS hit_mbps,round(read_bps / 1024 / 1024) AS read_mbps,round(check_bps / 1024 / 1024) AS check_mbps,round(clean_bps / 1024 / 1024) AS clean_mbps,
round(backend_bps / 1024 / 1024) AS backend_mbps,
round(wal_written_bps / 1024 / 1024) AS wal_written_mbps,
ram_pct
FROM test_metric_summary,testset
WHERE 
     testset.server=test_metric_summary.server AND
     testset.set=test_metric_summary.set AND
     metric like '%rMB/s'
ORDER BY server,set,scale,clients;

DROP VIEW write_io_summary;
CREATE VIEW write_io_summary AS
SELECT
testset.info,
server_num_proc,server_mem_gb,server_disk_gb,
test_metric_summary.server,test_metric_summary.set,
script,scale,clients,multi,test,tps,
metric,round(min) AS write_min,round(avg) AS write_avg,round(max) AS write_max,
round(read_bps / 1024 / 1024) AS read_mbps,round(hit_bps / 1024 / 1024) AS hit_mbps,round(check_bps / 1024 / 1024) AS check_mbps,round(clean_bps / 1024 / 1024) AS clean_mbps,
round(backend_bps / 1024 / 1024) AS backend_mbps,
round(wal_written_bps / 1024 / 1024) AS wal_written_mbps,
ram_pct
FROM test_metric_summary,testset
WHERE 
     testset.server=test_metric_summary.server AND
     testset.set=test_metric_summary.set AND
     (metric ='disk0_MB/s' OR metric like '%wMB/s')
ORDER BY server,set,scale,clients;

DROP VIEW test_disk_summary;
CREATE VIEW test_disk_summary AS
SELECT
  w.server, w.set, w.info,
  w.script, w.scale, w.clients, w.multi,
  w.test, w.tps,
  read_min,read_avg,read_max, 
  w.read_mbps, 
  w.hit_mbps,
  w.check_mbps,
  w.clean_mbps,
  w.backend_mbps,
  write_min,write_avg,write_max,
  COALESCE(read_min,0) + write_min AS total_min,
  COALESCE(read_avg,0) + write_avg AS total_avg,
  COALESCE(read_max,0) + write_max AS total_max,
  w.wal_written_mbps,
  w.ram_pct
FROM write_io_summary w
    LEFT OUTER JOIN read_io_summary r ON
        (r.server = w.server AND
        r.set = w.set AND
        r.script = w.script AND
        r.scale = w.scale AND
        r.clients = w.clients AND
        r.test = w.test)
ORDER BY server,set,scale,clients;

ALTER TABLE tests ADD COLUMN artifacts jsonb;

DROP TABLE IF EXISTS test_buffercache;
CREATE TABLE test_buffercache (
    server text,
    test integer,
    schemaname text,
    relname text,
    bytes bigint,
    avg_usage numeric,
    max_usage smallint,
    isdirty boolean
);

CREATE INDEX idx_buffercache on test_buffercache(server,test);

DROP VIEW IF EXISTS test_stats CASCADE;
CREATE OR REPLACE VIEW test_stats AS
WITH test_wrap AS
  (SELECT *,
      CASE WHEN extract(epoch FROM (end_time - start_time))::bigint<1
          THEN 1::bigint ELSE extract(epoch FROM (end_time - start_time))::bigint END AS seconds
   FROM TESTS)
SELECT
  testset.set, testset.info, server.server,script,scale,clients,multi,rate_limit,test_wrap.test,
  round(dbsize / (1024 * 1024)) as dbsize_mb,
  round(tps) as tps, max_latency,
  round(blks_hit           * 8192 / seconds) AS hit_Bps,
  round(blks_read          * 8192 / seconds) AS read_Bps,
  round(buffers_checkpoint * 8192 / seconds) AS check_Bps,
  round(buffers_clean      * 8192 / seconds) AS clean_Bps,
  round(buffers_backend    * 8192 / seconds) AS backend_Bps,
  round(wal_written / seconds) AS wal_written_Bps,
  max_dirty,
  server_version,
  server_info,
  server_num_proc,
  server_mem_gb,
  server_disk_gb,
  server_details
FROM
  test_wrap
  RIGHT JOIN test_bgwriter ON
      test_wrap.test=test_bgwriter.test AND test_wrap.server=test_bgwriter.server
  RIGHT JOIN test_stat_database ON
      test_wrap.test=test_stat_database.test AND test_wrap.server=test_stat_database.server
  RIGHT JOIN testset ON testset.set=test_wrap.set and testset.server=test_wrap.server
  FULL OUTER JOIN server on test_wrap.server=server.server
ORDER BY server,set,info,script,scale,clients,test_wrap.test
;

DROP VIEW IF EXISTS test_metric_summary;
CREATE VIEW test_metric_summary AS
  WITH ts AS (
    SELECT test_stats.info,test_stats.server,test_stats.set,
      test_stats.script,test_stats.scale,test_stats.clients,
      test_stats.multi,test_stats.rate_limit,test_stats.test,test_stats.tps,
      hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
      server_num_proc,server_mem_gb,server_disk_gb
    FROM test_stats
    ORDER BY test_stats.server,test_stats.set,
      test_stats.script,test_stats.scale,test_stats.clients,test_stats.multi,test_stats.rate_limit,test_stats.test)
  SELECT ts.server,ts.set,ts.script,ts.scale,ts.clients,ts.test,ts.multi,ts.rate_limit,ts.tps,
    hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
    server_num_proc,server_mem_gb,server_disk_gb,
    round(100.0 * dbsize_mb / 1024 / server_mem_gb) AS ram_pct,
    metric,min(value) as min,round(avg(value)) as avg,max(value) as max
  FROM ts
  JOIN test_metrics_data ON ts.test=test_metrics_data.test AND ts.server=test_metrics_data.server
  GROUP BY test_metrics_data.metric,ts.server,ts.set,ts.info,ts.script,ts.scale,ts.clients,ts.multi,ts.rate_limit,ts.test,ts.tps,
    hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
    server_num_proc,server_mem_gb,server_disk_gb
  ORDER BY test_metrics_data.metric,ts.server,ts.set,ts.info,ts.script,ts.scale,ts.clients,ts.multi,ts.rate_limit,ts.test,ts.tps,
    hit_bps,read_bps,check_bps,clean_bps,backend_bps,wal_written_bps,dbsize_mb,
    server_num_proc,server_mem_gb,server_disk_gb;

ALTER TABLE tests ADD COLUMN server_mem_gb int;
UPDATE tests t SET server_mem_gb=(SELECT max(s.server_mem_gb) FROM server s WHERE t.server=s.server);
