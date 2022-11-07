SELECT  test,  server.server_cpu AS cpu,
substring(server_version,1,18),
pg_size_pretty(dbsize) AS dbsize,
round((artifacts->'overall')::numeric/60/60,1) AS hours
from tests,server
where script like 'osm2pgsql%' and tests.server=server.server
order by tests.server,script,test;

