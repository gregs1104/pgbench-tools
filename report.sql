SELECT
  set,scale,test,script,clients,workers,
  round(tps) AS tps,
  round(1000*avg_latency)/1000 AS avg_latency,
  round(1000*percentile_90_latency)/1000 AS "90%<",
  1000*round(max_latency)/1000 AS max_latency,
  trans
FROM tests
ORDER BY set,scale,script,clients,test; 
