-- Save custom metrics that import into pgbench-tools test_metrics table.
-- Runs with timed-os-stats as long as first field starts with "|" delimiter.

SELECT
  --current_timestamp || '|' AS now,
  ' ',
  count(*) AS tot,
  'pg_clients_' || coalesce(state,'inactive') AS metric
  FROM pg_stat_activity
    WHERE backend_type='client backend'
    GROUP BY state
UNION
SELECT
  ' ',
  ROUND((EXTRACT(EPOCH FROM max(current_timestamp - backend_start)))) AS query_runtime_sec,
  'pg_max_query_runtime_sec' AS metric
  FROM pg_stat_activity
    WHERE backend_type='client backend'
UNION
SELECT
  ' ',
  pg_database_size(current_database()),
  'pg_db_size';

\watch 5
