-- A corriger pour f avg ?

SELECT DISTINCT
  server,set,script,scale,clients,workers,
  round(tps) AS tps,
  max_latency,
 percentile_90_latency as p90_latency
FROM
(
  SELECT
    server,set,script,scale,clients,workers,
    max(tps) AS tps,
    max_latency,
    percentile_90_latency
  FROM tests
  GROUP BY server,set,script,scale,clients,workers,percentile_90_latency,max_latency
) AS grouped
--GROUP BY server,set,script,scale,clients,workers,round(tps)
ORDER BY tps DESC LIMIT 20;
