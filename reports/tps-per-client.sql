SELECT
  server,set,script,scale,
  pg_size_pretty(avg(dbsize)::int8) AS db_size,
--  pg_size_pretty(avg(dbsize)::int8 / scale) AS size_per_scale,
  clients,
--  rate_limit,
  round(avg(tps)) as tps,
  round(avg(tps)/clients) as per_cl,
  round(1000 * avg(percentile_90_latency))/1000 AS "90%<",
  round(1000 * avg(max_latency))/1000 AS max_lat
--  to_char(avg(end_time -  start_time),'HH24:MI:SS') AS runtime
FROM tests 
GROUP BY server,set,script,scale,clients,rate_limit
ORDER BY server,set,script,scale,clients,rate_limit; 
