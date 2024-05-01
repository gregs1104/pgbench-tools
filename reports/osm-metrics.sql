\echo Average write rate MBps
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,test,round(avg(avg)) AS avg_write_Mbps
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric  like 'disk%_MB/s' OR metric like '%wMB/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,avg_write_Mbps FROM t
\crosstabview

\echo Maximum write rate MBps
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,test,round(max(max)) AS max_write_MBps
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric  like 'disk%_MB/s' OR metric like '%wMB/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,max_write_MBps FROM t
\crosstabview

\echo Maximum disk write ops
WITH t AS
  (SELECT
     server || '-' || set::text AS server,test,round(max(max)) AS writes
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric like 'disk%_tps' OR metric like '%_w/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,writes as write_count FROM t
\crosstabview

\echo Average disk write ops
WITH t AS 
  (SELECT
     server || '-' || set::text AS server,test,round(avg(avg)) AS writes
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric like 'disk%_tps' OR metric like '%_w/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,writes AS avg_writes FROM t
\crosstabview

\echo Linux max disk util%
WITH t AS (SELECT server || '-' || set::text AS server,test,max(max) as max
FROM test_metric_summary
WHERE
  (script like 'osm2pgsql%') AND
  (metric like '%util')
GROUP BY server,set,test
ORDER BY test
)
SELECT test,server,CASE WHEN max>100 THEN 100 ELSE round(max) END AS max FROM t
\crosstabview

\echo Linux avg disk util%
WITH t AS (SELECT server || '-' || set::text AS server,test,avg(avg) as avg
FROM test_metric_summary
WHERE
  (script like 'osm2pgsql%') AND
  (metric like '%util')
GROUP BY server,set,test
ORDER BY test
)
SELECT test,server,CASE WHEN avg>100 THEN 100 ELSE round(avg) END AS util FROM t
\crosstabview

\echo Linux per-disk avg disk util%
WITH t AS (SELECT server || '-' || set::text AS server,metric,avg(avg) as avg
FROM test_metric_summary
WHERE
  (script like 'osm2pgsql%') AND
  (metric like '%util')
GROUP BY server,set,metric
ORDER BY server,set,metric
)
SELECT metric,server,CASE WHEN avg>100 THEN 100 ELSE round(avg) END AS util FROM t
ORDER BY server,metric;
\crosstabview

\echo Max read rate MBps
WITH t AS
  (SELECT
     server || '-' || set::text AS server,test,round(max(max)) AS max_read_MBps
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric  like 'disk%_MB/s' OR metric like '%rMB/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,max_read_MBps FROM t
\crosstabview

\echo Average read rate MBps
WITH t AS
  (SELECT
     server || '-' || set::text AS server,test,round(avg(avg)) AS avg_read_Mbps
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric  like 'disk%_MB/s' OR metric like '%rMB/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,avg_read_Mbps FROM t
\crosstabview

\echo Maximum disk read ops
WITH t AS
  (SELECT
     server || '-' || set::text AS server,test,round(max(max)) AS reads
   FROM test_metric_summary
   WHERE
     (script like 'osm2pgsql%') AND
     (metric like 'disk%_tps' OR metric like '%_r/s')
   GROUP BY server,set,test
   ORDER BY test
  )
SELECT test,server,reads AS read_count FROM t
\crosstabview

\echo Average disk read ops
  WITH t AS
    (SELECT
       server || '-' || set::text AS server,test,round(avg(avg)) AS reads
     FROM test_metric_summary
     WHERE
       (script like 'osm2pgsql%') AND
       (metric like 'disk%_tps' OR metric like '%_r/s')
     GROUP BY server,set,test
     ORDER BY test
    )
  SELECT test,server,reads AS avg_reads FROM t
\crosstabview
