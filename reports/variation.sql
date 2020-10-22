WITH tps_range AS
(
  SELECT 
  round(min(tps)) as min,
  round(avg(tps)) as avg,
  round(max(tps)) as max,
  round(100*(max(tps)-min(tps))/min(tps)) as diff_pct,
  count(*) as samples,
  server,script,set,scale,clients
  FROM tests 
  GROUP BY server,script,set,scale,clients
  ORDER BY server,script,set,scale,clients
) 
SELECT * FROM tps_range WHERE samples>2;


