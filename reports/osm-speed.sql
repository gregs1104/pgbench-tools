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
  round((artifacts->'overall')::numeric/60/60,1) AS hours
FROM tests,server
WHERE script LIKE 'osm2pgsql%' AND tests.server=server.server
ORDER BY tests.server,script,test;
