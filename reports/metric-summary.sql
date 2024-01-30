\echo Summary scorecard
WITH max AS (
  SELECT server,max(scale) AS s FROM tests GROUP BY server
  )
SELECT
  server,
  script || '-' || CASE WHEN scale=100 THEN 'mem' ELSE 'seek' END || '-' || clients,
  ROUND(AVG(tps))
FROM tests
  WHERE (scale=100 OR scale IN (SELECT s FROM max WHERE tests.server=max.server)) AND
    (clients=1 OR clients=32) AND
    (script='select' OR script='insert')
    GROUP BY server,script,scale,clients
    ORDER BY server,script,scale,clients
\crosstabview

\echo Average write rate MBps
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,clients,round(avg(avg)) AS avg_write_Mbps
   FROM test_metric_summary
   WHERE
     script='insert' AND
     (metric='disk0_MB/s' OR metric like '%wMB/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,avg_write_Mbps FROM t
\crosstabview

\echo Maximum write rate MBps
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,clients,round(max(max)) AS max_write_MBps
   FROM test_metric_summary
   WHERE
     script='insert' AND
     (metric='disk0_MB/s' OR metric like '%wMB/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,max_write_MBps FROM t
\crosstabview

\echo Maximum disk write ops
WITH t AS
  (SELECT
     server || '-' || set::text AS server,clients,round(max(max)) AS writes
   FROM test_metric_summary
   WHERE
     script='insert' AND
     (metric='disk0_tps' OR metric like '%_w/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,writes as write_count FROM t
\crosstabview

\echo Average disk write ops
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,clients,round(avg(avg)) AS writes
   FROM test_metric_summary
   WHERE
     script='insert' AND
     (metric='disk0_tps' OR metric like '%_w/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,writes AS avg_writes FROM t
\crosstabview

\echo Average read rate MBps
WITH t AS
  (SELECT
     server || '-' || set::text AS server,clients,round(avg(avg)) AS avg_read_Mbps
   FROM test_metric_summary
   WHERE
     (script='insert' OR script='select' OR script='select-pages') AND
     (metric='disk0_MB/s' OR metric like '%rMB/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,avg_read_Mbps FROM t
\crosstabview

\echo Max read rate MBps
WITH t AS
  (SELECT
     server || '-' || set::text AS server,clients,round(max(max)) AS max_read_Mbps
   FROM test_metric_summary
   WHERE
     (script='insert' OR script='select' OR script='select-pages') AND
     (metric='disk0_MB/s' OR metric like '%rMB/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,max_read_Mbps FROM t
\crosstabview

\echo Average reads/sec (Linux) or total ops/sec (Mac)
WITH t AS
  (SELECT
     server || '-' || set::text AS server,clients,round(avg(avg)) AS avg_read_per_sec
   FROM test_metric_summary
   WHERE
     (script='insert' OR script='select' OR script='select-pages') AND
     (metric='disk0_tps' OR metric like '%_r/s') AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,avg_read_per_sec FROM t
\crosstabview


\echo Fastest second of TPS
WITH t AS (
   SELECT
     server || '-' || set::text AS server,clients,round(max(avg)) AS tps
   FROM test_metric_summary
   WHERE
     (script='insert' OR script='select') AND
     metric='rate' AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,tps AS avg_tps FROM t
\crosstabview 

\echo Average TPS
WITH t AS (
   SELECT
     server || '-' || set::text AS server,clients,round(avg(avg)) AS tps
   FROM test_metric_summary
   WHERE
     (script='insert' OR script='select') AND
     metric='rate' AND
     clients IN (1,2,4,8,16,32,64,128)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,tps AS avg_tps FROM t
\crosstabview

\echo Commit time milliseconds
WITH t AS (SELECT server || '-' || set::text AS server,clients,
  ROUND(1000.0 / avg(tps),3) AS commit_ms
FROM test_metric_summary
WHERE
  script='insert' AND
  (metric='disk0_MB/s' OR metric like '%wMB/s') AND
  clients IN (1,2,4,8,16,32,64,128)
GROUP BY server,set,clients
ORDER BY server,set,clients
)
SELECT * FROM t
\crosstabview

\echo Commit time usec
WITH t AS (SELECT server || '-' || set::text AS server,clients,
  ROUND(1000 * 1000.0 / avg(tps),0) AS commit_ms
FROM test_metric_summary
WHERE
  script='insert' AND
  (metric='disk0_MB/s' OR metric like '%wMB/s') AND
  clients IN (1,2,4,8,16,32,64,128)
GROUP BY server,set,clients
ORDER BY server,set,clients
)
SELECT * FROM t
\crosstabview


\echo Linux disk util% by scale
WITH t AS (SELECT server || '-' || set::text AS server,scale,max(max) as max
FROM test_metric_summary
WHERE
  (script='insert' OR script='select') AND
  (metric like '%util') AND
   clients IN (1,2,4,8,16,32,64,128)
GROUP BY server,set,scale
ORDER BY server,set,scale
)
SELECT server,scale,CASE WHEN max>100 THEN 100 ELSE round(max) END FROM t
\crosstabview

\echo Linux disk util% by clients
WITH t AS (SELECT server || '-' || set::text AS server,clients,max(max) as max
FROM test_metric_summary
WHERE
  (script='insert' OR script='select') AND
  (metric like '%util') AND
   clients IN (1,2,4,8,16,32,64,128)
GROUP BY server,set,clients
ORDER BY server,set,clients
)
SELECT server,clients,CASE WHEN max>100 THEN 100 ELSE round(max) END FROM t
\crosstabview

