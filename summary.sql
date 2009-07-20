select 
  set,scale,
  pg_size_pretty(avg(dbsize)::int8) as db_size,
  clients,
  round(avg(tps)) as tps,
  round(1000 * avg(avg_latency))/1000 as avg_latency,
  round(1000 * avg(max_latency))/1000 as max_latency ,
  round(1000 * avg(percentile_90_latency))/1000 as "90%<",
  to_char(avg(end_time -  start_time),'HH24:MI:SS') as runtime
from tests 
group by set,scale,clients 
order by set,scale,clients; 
