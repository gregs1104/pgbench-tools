SELECT
  set,script,scale,clients,workers,
  round(tps) as tps
FROM tests
ORDER BY tps DESC LIMIT 20;
