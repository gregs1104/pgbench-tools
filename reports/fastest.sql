SELECT
  server,set,script,scale,clients,workers,
  round(tps) AS tps
FROM
(
  SELECT
    server,set,script,scale,clients,workers,
    max(tps) AS tps
  FROM tests
  GROUP BY server,set,script,scale,clients,workers
) AS grouped
ORDER BY tps DESC LIMIT 20;
