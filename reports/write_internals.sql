SELECT
  to_char(end_time,'YYYY/MM/DD') AS run,
  --tests.test,
  tests.server_cpu AS cpu,
  tests.server_mem_gb AS mem_gb,
  script,
  set,
  substring(server_version,1,16) AS server_ver,
  --clients AS procs,
  --multi AS shift,
  scale,
  pg_size_pretty(dbsize) AS dbsize,
  round(extract(epoch from (tests.end_time - tests.start_time))/60/60,2) as hours,
  (
  SELECT value FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='shared_buffers'
    LIMIT 1
  ) as shared,
  (SELECT value FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='maintenance_work_mem'
    LIMIT 1
  ) as maint,
  (
  SELECT test_settings.setting FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='fsync'
    LIMIT 1
  ) as fsync,
  (
  SELECT pg_size_pretty(test_settings.setting::int8 * 1024 * 1024) FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='max_wal_size'
    LIMIT 1
  ) as max_wal,
  (
  SELECT test_settings.setting::integer / 60 FROM test_settings WHERE
    test_settings.server=tests.server AND test_settings.test=tests.test AND
    test_settings.name='checkpoint_timeout'
    LIMIT 1
  ) as timeout,
  round(extract(epoch from (tests.end_time - tests.start_time)) / (test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) / 60,1) as chkp_mins,
  pg_size_pretty(round(60*60*buffers_checkpoint * 8192 / extract(epoch from (tests.end_time - tests.start_time)))::bigint) as chkp_bph,
  pg_size_pretty(round(60*60*buffers_clean * 8192 / extract(epoch from (tests.end_time - tests.start_time)))::bigint) as clean_bph,
--  pg_size_pretty(round(buffers_checkpoint * 8192 / extract(epoch from (tests.end_time - tests.start_time)))::bigint) as chkp_bytes_per_sec,
--  60*60*(test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) / extract(epoch from (tests.end_time - tests.start_time))::bigint as chkp_per_hour,
--  test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req as chkpts,
--  test_bgwriter.checkpoints_timed as timed,test_bgwriter.checkpoints_req as req,
  CASE WHEN
    test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req > 0 THEN
    round(100::numeric * test_bgwriter.checkpoints_timed/(test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req))
  ELSE
    100
  END AS timed_pct,
  round(100.0 * blks_hit / (blks_read + blks_hit)) as hit_pct,
  round(blks_hit * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024 / 1024,1) AS hit_gbps,
  round(blks_read * 8192 / extract(epoch from (tests.end_time - tests.start_time)) / 1024 / 1024 / 1024,1) AS read_gbps,
  pg_size_pretty(round(wal_written / extract(epoch from (tests.end_time - tests.start_time)))::bigint) AS wal_bps,
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
  ) AS max_write_MBps
FROM tests,server,test_bgwriter,test_stat_database
WHERE
--    script LIKE ':-i%' AND
  tests.server=server.server AND
  tests.test=test_bgwriter.test AND tests.server=test_bgwriter.server AND
  tests.test=test_stat_database.test AND tests.server=test_stat_database.server AND
  extract(epoch from (tests.end_time - tests.start_time))::bigint > 0 AND
  (test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) > 0
ORDER BY tests.server,tests.server_cpu,tests.server_mem_gb,
  script,
  server_version,tests.set,
  multi,scale,fsync,shared,maint,max_wal,timeout,extract(epoch from (tests.end_time - tests.start_time)) desc;
