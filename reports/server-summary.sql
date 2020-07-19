SELECT
  server,set,script,
  round(avg(tps)) as tps,
  round(1000 * avg(avg_latency))/1000 AS avg_latency,
  round(1000 * avg(max_latency))/1000 AS max_latency
FROM tests 
GROUP BY server,set,script 
ORDER BY server,set,script; 
