-- Advanced report of background write effectiveness

SELECT
  set,scale,clients,rate_limit as "limit",tps,max_latency,
--  cast(date_trunc('minute',start_time) AS timestamp) AS start,
  date_trunc('second',elapsed) AS elapsed,
  (checkpoints_timed + checkpoints_req) as ckpt,
  date_trunc('second',elapsed / (checkpoints_timed + checkpoints_req)) AS interval,
  (100 * checkpoints_req) / (checkpoints_timed + checkpoints_req)
    AS ckpt_req,
  pg_size_pretty(buffers_checkpoint * block_size / (checkpoints_timed + checkpoints_req))
    AS avg_ckpt_write,
  100 * buffers_checkpoint / (buffers_checkpoint + buffers_clean + buffers_backend) AS ckpt_write,
  100 * buffers_backend / (buffers_checkpoint + buffers_clean + buffers_backend) AS backend_write,
  100 * buffers_clean / (buffers_checkpoint + buffers_clean + buffers_backend) AS clean_write,
  pg_size_pretty(cast(block_size::int8 * (buffers_checkpoint + buffers_clean + buffers_backend) / extract(epoch FROM elapsed) AS int8)) AS writes_per_sec,
  pg_size_pretty(cast(block_size * (buffers_alloc) / extract(epoch FROM elapsed) AS int8)) AS alloc_per_sec,
  buffers_backend_fsync as backend_sync,
  pg_size_pretty(max_dirty::int8) as max_dirty
FROM
  (
  select 
  set,scale,tests.test,clients,rate_limit,round(tps) as tps,
  max_latency,
  start_time,
  end_time -  start_time as elapsed,  
  checkpoints_timed,
  checkpoints_req,
  buffers_checkpoint,
  buffers_clean,
  buffers_backend,
  buffers_alloc,
  buffers_backend_fsync,
  max_dirty,
  (SELECT cast(current_setting('block_size') AS int8)) AS block_size
from test_bgwriter right join tests on tests.test=test_bgwriter.test WHERE NOT end_time is NULL
) raw
WHERE (checkpoints_timed + checkpoints_req)>0
order by scale,set,clients,rate_limit,test;

