SELECT
  set,script,scale,clients,workers,
  round(tps) AS tps
FROM
(
  SELECT
    set,script,scale,clients,workers,
    max(tps) AS tps
  FROM tests
  GROUP BY set,script,scale,clients,workers
) AS grouped
ORDER BY tps DESC LIMIT 20;
