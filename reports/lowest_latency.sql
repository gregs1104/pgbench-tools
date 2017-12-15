SELECT
  set,script,scale,clients,workers,
  p90_latency
FROM
(
 SELECT
    set,script,scale,clients,workers,
    min(percentile_90_latency) AS p90_latency
  FROM tests
  WHERE 
	percentile_90_latency IS NOT NULL
  GROUP BY set,script,scale,clients,workers
) AS grouped
ORDER BY p90_latency LIMIT 20;
