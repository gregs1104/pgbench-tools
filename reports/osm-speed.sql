SELECT
  test,
  server.server_cpu AS cpu,
  --script,
  --set,
  --substring(server_version,1,16) AS server_ver,
  clients AS procs,
  scale AS ncache,
  multi AS shift,
  pg_size_pretty(dbsize) AS dbsize,
  round((artifacts->'overall')::numeric/60/60,2) AS hours
FROM tests,server
WHERE script LIKE 'osm2pgsql%' AND tests.server=server.server
ORDER BY tests.server,script,test;

SELECT
--  server.server,
  server.server_cpu AS cpu,
  tests.server_mem_gb AS mem_gb,
  substring(server_version,1,18) as server_ver,
  --set,
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
  round((artifacts->'relation_count')::numeric/(artifacts->'relation_seconds')::numeric,0) AS rel_ps
FROM tests,server
WHERE script LIKE 'osm2pgsql%' AND tests.server=server.server
ORDER BY tests.server,script,set,multi,scale,test;
