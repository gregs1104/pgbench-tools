DROP VIEW IF EXISTS write_internals;
CREATE OR REPLACE VIEW write_internals AS
 SELECT
  tests.server || ' - ' || tests.set::text  || ' - ' || tests.test::text AS ref_info,
  to_char(end_time,'YYYY/MM/DD') AS run,
  tests.server_cpu AS cpu,
  tests.server_mem_gb AS mem_gb,
  tests.server_disk AS disk,
  tests.server_os_release AS os_rel,
  substring(server_version,1,16) AS server_ver,
  tests.conn_method AS conn,
  script,
  set,
  clients,
  scale,
  CASE WHEN jsonb_exists(artifacts, 'node_count')
    THEN (artifacts->'node_count')::numeric ELSE 0 END AS nodes,
  round(dbsize / 1024 / 1024 / 1024,1) AS db_gb,
  tps,  avg_latency, percentile_90_latency, max_latency, rate_limit,
  round(extract(epoch from (tests.end_time - tests.start_time))/60/60,2) as hours,
  CASE WHEN jsonb_exists(artifacts, 'node_count') AND jsonb_exists(artifacts, 'overall')
    THEN round((artifacts->'node_count')::numeric / (artifacts->'overall')::numeric / 1000,0)
    ELSE 0 END AS nodes_kips,
  (
  SELECT round(numeric_value / 1024 / 1024 / 1024,1) FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='shared_buffers'
    LIMIT 1
  ) as shared_gb,
  (SELECT round(numeric_value / 1024 / 1024 / 1024,1) FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='maintenance_work_mem'
    LIMIT 1
  ) as maint_gb,
  (
  SELECT round(test_settings.numeric_value / 1024 / 1024 / 1024,1) FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='max_wal_size'
    LIMIT 1
  ) as max_wal_gb,
  (
  SELECT test_settings.setting FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='fsync'
    LIMIT 1
  ) as fsync,
  (
  SELECT test_settings.setting FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='wal_level'
    LIMIT 1
  ) as wal_level,
  (
  SELECT test_settings.setting::integer / 60 FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='checkpoint_timeout'
    LIMIT 1
  ) as timeout,
  CASE WHEN
    (test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) > 0
    THEN round(100::numeric * test_bgwriter.checkpoints_timed/(test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req))
    ELSE 100 END AS timed_pct,
  CASE WHEN
    (test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) > 0
    THEN round(extract(epoch from (tests.end_time - tests.start_time)) / (test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) / 60,1)
    ELSE 0 END AS chkp_mins,
  round(60*60*buffers_checkpoint * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024) as chkp_mbph,
  round(60*60*buffers_clean * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024) as clean_mbph,
  round(60*60*buffers_backend * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024) as backend_mbph,
--pg_size_pretty(round(60*60*buffers_checkpoint * 8192 / extract(epoch from (tests.end_time - tests.start_time)))::bigint) as chkp_bph,
--pg_size_pretty(round(60*60*buffers_clean * 8192 / extract(epoch from (tests.end_time - tests.start_time)))::bigint) as clean_bph,
--  pg_size_pretty(round(buffers_checkpoint * 8192 / extract(epoch from (tests.end_time - tests.start_time)))::bigint) as chkp_bytes_per_sec,
--  60*60*(test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) / extract(epoch from (tests.end_time - tests.start_time))::bigint as chkp_per_hour,
--  test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req as chkpts,
--  test_bgwriter.checkpoints_timed as timed,test_bgwriter.checkpoints_req as req,
  CASE WHEN
    (test_bgwriter.buffers_checkpoint + test_bgwriter.buffers_clean) > 0
    THEN round(100::numeric * test_bgwriter.buffers_clean/(test_bgwriter.buffers_checkpoint + test_bgwriter.buffers_clean))
    ELSE 100 END AS cleaned_pct,
  max_dirty,
  round(100.0 * blks_hit / (blks_read + blks_hit)) as hit_pct,
  round(blks_hit * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024,1) AS hit_mbps,
  round(blks_read * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024,1) AS read_mbps,
--  pg_size_pretty(round(wal_written / extract(epoch from (tests.end_time - tests.start_time)))::bigint) AS wal_bps,
  round(wal_written / 1024 / 1024 / extract(epoch from (tests.end_time - tests.start_time)),1) AS wal_mbps,
  (
  SELECT round(avg(test_metrics_data.value)) FROM test_metrics_data
  WHERE
    tests.server=test_metrics_data.server AND
    tests.test=test_metrics_data.test AND
    -- TODO Support secondary Mac disks
    (test_metrics_data.metric='disk0_MB/s' OR test_metrics_data.metric LIKE '%wMB/s')
  ) AS avg_write_MBps,
  (
  SELECT round(max(test_metrics_data.value)) FROM test_metrics_data
  WHERE
    tests.server=test_metrics_data.server AND
    tests.test=test_metrics_data.test AND
    -- TODO Support secondary Mac disks
    (test_metrics_data.metric='disk0_MB/s' OR test_metrics_data.metric LIKE '%wMB/s')
  ) AS max_write_MBps,
  (
  SELECT round(avg(test_metrics_data.value)) FROM test_metrics_data
  WHERE
    tests.server=test_metrics_data.server AND
    tests.test=test_metrics_data.test AND
    -- TODO Support secondary Mac disks
    (test_metrics_data.metric='disk0_MB/s' OR test_metrics_data.metric LIKE '%rMB/s')
  ) AS avg_read_MBps,
  (
  SELECT round(max(test_metrics_data.value)) FROM test_metrics_data
  WHERE
    tests.server=test_metrics_data.server AND
    tests.test=test_metrics_data.test AND
    -- TODO Support secondary Mac disks
    (test_metrics_data.metric='disk0_MB/s' OR test_metrics_data.metric LIKE '%rMB/s')
  ) AS max_read_MBps
FROM tests,server,test_bgwriter,test_stat_database
WHERE
--    script LIKE ':-i%' AND
  tests.server=server.server AND
  tests.test=test_bgwriter.test AND tests.server=test_bgwriter.server AND
  tests.test=test_stat_database.test AND tests.server=test_stat_database.server AND
  extract(epoch from (tests.end_time - tests.start_time))::bigint > 0
ORDER BY tests.server,tests.server_cpu,tests.server_mem_gb,
  script,
  server_version,tests.set,
  multi,scale,fsync,shared_gb,maint_gb,max_wal_gb,timeout,extract(epoch from (tests.end_time - tests.start_time)) desc;

--SELECT * FROM write_internals;