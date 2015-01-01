SELECT
  set,scale,
  pg_size_pretty(avg(dbsize)::int8) AS db_size,
  pg_size_pretty(avg(dbsize)::int8 / scale) AS size_per_scale,
  clients,
  round(avg(tps)) as tps,
  round(avg(tps)/clients) as tps_per_client,
  round(1000 * avg(max_latency))/1000 AS max_latency ,
  to_char(avg(end_time -  start_time),'HH24:MI:SS') AS runtime
FROM tests 
GROUP BY set,scale,clients 
ORDER BY set,scale,clients; 
