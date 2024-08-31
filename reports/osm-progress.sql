WITH t1 AS (
  SELECT * FROM tests WHERE tests.end_time IS NULL
  ORDER BY TEST DESC LIMIT 1),
history AS (
  SELECT
  t1.test,
  t2.test,
  extract(epoch from (t2.end_time - t2.start_time)) AS baseline_seconds,
  extract(epoch from (current_timestamp - t1.start_time)) AS running_seconds,
  t2.dbsize AS final_size,
  pg_database_size('gis') as current_size

  FROM t1, tests t2 WHERE
  t2.test<t1.test AND
  t2.script=t1.script AND
  t2.scale=t1.scale AND
  t2.clients=t1.clients AND
  t2.workers=t1.workers
  ORDER BY extract(epoch from (t2.end_time - t2.start_time)) DESC
  LIMIT 25
  ),
baselines AS (
  SELECT
  min(running_seconds) AS runtime,
  min(baseline_seconds) AS low,
  avg(baseline_seconds) AS avg,
  max(baseline_seconds) AS max,
  max(final_size) AS max_size,
  min(current_size) AS current_size
  FROM history)
SELECT
  round(100.0::numeric * runtime / max,1) AS pct_runtime,
  round(100.0::numeric * current_size / max_size,1) AS pct_disk,
  round(current_size::numeric / 1024 / 1024 / 1023 / runtime * 60 * 60,1) AS gb_per_hr
FROM baselines
;
