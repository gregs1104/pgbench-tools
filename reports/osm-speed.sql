SELECT
  test,
  tests.server_cpu AS cpu,
  tests.server_mem_gb AS mem_gb,
  --script,
  set,
  --substring(server_version,1,16) AS server_ver,
  clients AS procs,
  scale AS ncache,
  multi AS shift,
  pg_size_pretty(dbsize) AS dbsize,
  round((artifacts->'overall')::numeric/60/60,2) AS hours,
  round((artifacts->'node_count')::numeric / (artifacts->'overall')::numeric / 1000,0) AS nodes_kips
FROM tests,server
WHERE script LIKE 'osm2pgsql%' AND tests.server=server.server
ORDER BY tests.server,tests.set,tests.server_cpu,tests.server_mem_gb,script,multi,scale,test;

SELECT
--  server.server,
  tests.server_cpu AS cpu,
  tests.server_mem_gb AS mem_gb,
  substring(server_version,1,16) as server_ver,
  set,
  --script,
  --test,
  clients AS procs,
  scale AS ncache,
  multi AS shift,
  pg_size_pretty(dbsize) AS dbsize,
  --round((artifacts->'overall')::numeric,0) AS overall_sec,
  --round((artifacts->'planet_osm_polygon')::numeric,0) AS polygon_sec,
  --round((artifacts->'planet_osm_line')::numeric,0) AS line_sec,
  --round((artifacts->'planet_osm_point')::numeric,0) AS point_sec,
  round((artifacts->'overall')::numeric/60/60,2) AS overall,
  round((artifacts->'planet_osm_polygon')::numeric/60/60,2) AS polygon,
  round((artifacts->'planet_osm_line')::numeric/60/60,2) AS line,
  round((artifacts->'planet_osm_point')::numeric/60/60,2) AS point,
  --round((artifacts->'planet_osm_roads')::numeric/60/60,2) AS roads,
  round((artifacts->'node_count')::numeric/1000/(artifacts->'node_seconds')::numeric,0) AS node_kps,
  round((artifacts->'way_count')::numeric/1000/(artifacts->'way_seconds')::numeric,0) AS way_kps,
  round((artifacts->'relation_count')::numeric/(artifacts->'relation_seconds')::numeric,0) AS rel_ps,
  round((artifacts->'node_count')::numeric / (artifacts->'overall')::numeric / 1000,0) AS nodes_kips
FROM tests,server
WHERE script LIKE 'osm2pgsql%' AND tests.server=server.server
ORDER BY tests.server,tests.set,tests.server_cpu,tests.server_mem_gb,script,multi,scale,test;

-- Report showing common tuned parameters for buffers and durability
SELECT
  to_char(end_time,'YYYY/MM/DD') AS run,
  --tests.test,
  tests.server_cpu AS cpu,
  tests.server_mem_gb AS mem_gb,
  --script,
  set,
  substring(server_version,1,16) AS server_ver,
  --clients AS procs,
  --multi AS shift,
  --scale AS ncache,
  pg_size_pretty(dbsize) AS dbsize,
  round((artifacts->'overall')::numeric/60/60,2) AS hrs,
  round((artifacts->'node_count')::numeric / (artifacts->'overall')::numeric / 1000,0) AS nodes_kips,
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
  pg_size_pretty(round(wal_written / extract(epoch from (tests.end_time - tests.start_time)))::bigint) AS wal_bps
FROM tests,server,test_bgwriter
WHERE
  script LIKE 'osm2pgsql%' AND tests.server=server.server AND
  tests.test=test_bgwriter.test AND tests.server=test_bgwriter.server AND
  extract(epoch from (tests.end_time - tests.start_time))::bigint > 0 AND
  (test_bgwriter.checkpoints_timed + test_bgwriter.checkpoints_req) > 0
ORDER BY tests.server,tests.server_cpu,tests.server_mem_gb,
-- script removed because OSM numbering doesn't sort correctly in alphanumeric
  server_version,tests.set,
  multi,scale,fsync,shared,maint,max_wal,timeout,(artifacts->'overall')::numeric desc;
