\echo Average write rate MBps
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,clients,round(avg(tps)) AS tps
   FROM test_metric_summary
   WHERE
     script='insert' AND
     (metric='disk0_MB/s' OR metric like '%wMB/s') AND
     clients IN (1,2,4,8,16,32)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,tps FROM t
\crosstabview

\echo Maximum write rate MBps
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,clients,round(max(max)) AS max_write_MBps
   FROM test_metric_summary
   WHERE
     script='insert' AND
     (metric='disk0_MB/s' OR metric like '%wMB/s') AND
     clients IN (1,2,4,8,16,32)
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
     clients IN (1,2,4,8,16,32)
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
     clients IN (1,2,4,8,16,32)
   GROUP BY server,set,clients
   ORDER BY server,set,clients
  )
SELECT server,clients,writes AS avg_writes FROM t
\crosstabview

\echo Fastest second of TPS
WITH t AS (
   SELECT
     server || '-' || set::text AS server,clients,round(max(avg)) AS tps
   FROM test_metric_summary
   WHERE
     script='insert' AND
     metric='rate' AND
     clients IN (1,2,4,8,16,32)
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
     script='insert' AND
     metric='rate' AND
     clients IN (1,2,4,8,16,32)
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
  clients IN (1,2,4,8,16,32)
GROUP BY server,set,clients
ORDER BY server,set,clients
)
SELECT * FROM t
\crosstabview

\echo Linux disk util%
WITH t AS (SELECT server || '-' || set::text AS server,scale,max(max) as max
FROM test_metric_summary
WHERE
  script='insert' AND
  (metric like '%util') AND
   clients IN (1,2,4,8,16,32)
GROUP BY server,set,scale
ORDER BY server,set,scale
)
SELECT server,scale,max FROM t
\crosstabview
