-- A corriger pour f avg ?

SELECT DISTINCT
  set,script,scale,clients,workers,
  round(tps) AS tps,
  max_latency,
 percentile_90_latency as p90_latency
FROM
(
  SELECT
    set,script,scale,clients,workers,
    max(tps) AS tps,
    max_latency,
    percentile_90_latency
  FROM tests
  GROUP BY set,script,scale,clients,workers,percentile_90_latency,max_latency
) AS grouped
--GROUP BY set,script,scale,clients,workers,round(tps)
ORDER BY tps DESC LIMIT 20;
