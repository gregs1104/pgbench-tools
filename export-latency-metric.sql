CREATE TEMPORARY TABLE tmp_lat_import AS 
  SELECT extract(epoch FROM date_trunc('second',ts)) AS collected, count(*) AS samples, min(latency) AS min_latency, round(1000*avg(latency))/1000 AS avg_latency, max(latency) AS max_latency FROM timing GROUP BY date_trunc('second',ts) LIMIT 0;
\copy tmp_lat_import FROM 'latency_1s.csv' WITH CSV HEADER
\copy (SELECT * FROM (SELECT collected,samples AS value,'tps' AS metric FROM tmp_lat_import UNION SELECT collected,min_latency,'min_latency' AS metric FROM tmp_lat_import UNION SELECT collected,max_latency,'max_latency' AS metric FROM tmp_lat_import UNION SELECT collected,avg_latency,'avg_latency' AS metric FROM tmp_lat_import) AS lat ORDER BY collected,metric) to 'latency_metric.csv' CSV HEADER
