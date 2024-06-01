WITH w AS
  (SELECT
     tests.server,tests.test,
     scale,script,set,
     metric,collected,
     max(value) AS max_write_MBps
   FROM test_metrics_data,tests
   WHERE
     tests.server=test_metrics_data.server AND
     tests.test=test_metrics_data.test AND
     script LIKE 'cbc%' AND
     (metric='disk0_MB/s' OR metric LIKE '%wMB/s')
   GROUP BY tests.server,tests.test,metric,scale,script,set,collected
   ORDER BY tests.server,tests.test,metric,scale,script,set,collected
  ),
r AS
  (SELECT
     tests.server,tests.test,
     scale,script,set,
     metric,collected,
     max(value) AS max_read_MBps
   FROM test_metrics_data,tests
   WHERE
     tests.server=test_metrics_data.server AND
     tests.test=test_metrics_data.test AND
     script LIKE 'cbc%' AND
     (metric='disk0_MB/s' OR metric LIKE '%rMB/s')
   GROUP BY tests.server,tests.test,metric,scale,script,set,collected
   ORDER BY tests.server,tests.test,metric,scale,script,set,collected
  ),
t AS
(SELECT r.server,r.test,r.scale,r.script,r.set,
  max_read_MBps,
  max_write_MBps,
  CASE WHEN r.metric LIKE '%rMB/s'
    THEN round(max_read_MBps + max_write_MBps)
    ELSE max_read_MBps
    END AS max_total_MBps
FROM r,w
WHERE
  r.server=w.server AND r.test=w.test AND
  r.set=w.set AND r.script=w.script AND
  r.scale=w.scale AND
  r.collected=w.collected
  ),
m AS
  (SELECT server,set,script,test,scale,
    max(max_read_MBps) AS max_read_MBps,
    max(max_write_MBps) AS max_write_MBps,
    max(max_total_MBps) AS max_total_MBps
  FROM t
  GROUP BY server,set,script,test,scale,max_total_MBps
  ),
best AS
  (SELECT
    server,scale,script,set,
    max_read_MBps,
    max_write_MBps,
    max_total_MBps,
    ROW_NUMBER()
    OVER(
        PARTITION BY server,scale,script
        ORDER BY max_total_MBps DESC
    )  AS r
    FROM m
    ORDER BY server,scale,script,max_total_MBps DESC
  )
SELECT 
    server,set,script,scale,
    round(max_read_MBps) AS max_read_MBps,
    round(max_write_MBps) AS max_write_MBps,
    round(max_total_MBps) AS max_total_MBps
FROM best WHERE r=1
ORDER BY max_total_MBps DESC,server,set,script,scale;

WITH w AS
  (SELECT
     tests.server,tests.test,
     scale,script,set,
     metric,collected,
     max(value) AS max_write_MBps
   FROM test_metrics_data,tests
   WHERE
     tests.server=test_metrics_data.server AND
     tests.test=test_metrics_data.test AND
     script LIKE 'cbc%' AND
     (metric='disk0_MB/s' OR metric LIKE '%wMB/s')
   GROUP BY tests.server,tests.test,metric,scale,script,set,collected
   ORDER BY tests.server,tests.test,metric,scale,script,set,collected
  ),
r AS
  (SELECT
     tests.server,tests.test,
     scale,script,set,
     metric,collected,
     max(value) AS max_read_MBps
   FROM test_metrics_data,tests
   WHERE
     tests.server=test_metrics_data.server AND
     tests.test=test_metrics_data.test AND
     script LIKE 'cbc%' AND
     (metric='disk0_MB/s' OR metric LIKE '%rMB/s')
   GROUP BY tests.server,tests.test,metric,scale,script,set,collected
   ORDER BY tests.server,tests.test,metric,scale,script,set,collected
  ),
t AS
(SELECT r.server,r.test,r.scale,r.script,r.set,
  max_read_MBps,
  max_write_MBps,
  CASE WHEN r.metric LIKE '%rMB/s'
    THEN round(max_read_MBps + max_write_MBps)
    ELSE max_read_MBps
    END AS max_total_MBps
FROM r,w
WHERE
  r.server=w.server AND r.test=w.test AND
  r.set=w.set AND r.script=w.script AND
  r.scale=w.scale AND
  r.collected=w.collected
  ),
m AS
  (SELECT server,set,script,test,scale,
    max(max_read_MBps) AS max_read_MBps,
    max(max_write_MBps) AS max_write_MBps,
    max(max_total_MBps) AS max_total_MBps
  FROM t
  GROUP BY server,set,script,test,scale,max_total_MBps
  ),
best AS
  (SELECT
    server,scale,script,set,
    max_read_MBps,
    max_write_MBps,
    max_total_MBps,
    ROW_NUMBER()
    OVER(
        PARTITION BY server,scale,script
        ORDER BY max_total_MBps DESC
    )  AS r
    FROM m
    ORDER BY server,scale,script,max_total_MBps DESC
  )
SELECT
    server,set,script,scale,
    round(max_read_MBps) AS max_read_MBps,
    round(max_write_MBps) AS max_write_MBps,
    round(max_total_MBps) AS max_total_MBps
FROM best WHERE r=1
ORDER BY max_write_MBps DESC,server,set,script,scale;

