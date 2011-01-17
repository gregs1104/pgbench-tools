-- Advanced report of background write effectiveness

SELECT
  set,scale,clients,tps,
--  cast(date_trunc('minute',start_time) AS timestamp) AS start,
  date_trunc('second',elapsed) AS elapsed,
  (checkpoints_timed + checkpoints_req) as ckpt,
  date_trunc('second',elapsed / (checkpoints_timed + checkpoints_req)) AS ckpt_interval,
  (100 * checkpoints_req) / (checkpoints_timed + checkpoints_req)
    AS ckpt_req_pct,
  pg_size_pretty(buffers_checkpoint * block_size / (checkpoints_timed + checkpoints_req))
    AS avg_ckpt_write,
  100 * buffers_checkpoint / (buffers_checkpoint + buffers_clean + buffers_backend) AS ckpt_write_pct,
  100 * buffers_backend / (buffers_checkpoint + buffers_clean + buffers_backend) AS backend_write_pct,
  100 * buffers_clean / (buffers_checkpoint + buffers_clean + buffers_backend) AS clean_write_pct,
  pg_size_pretty(cast(block_size::int8 * (buffers_checkpoint + buffers_clean + buffers_backend) / extract(epoch FROM elapsed) AS int8)) AS writes_per_sec,
  pg_size_pretty(cast(block_size * (buffers_alloc) / extract(epoch FROM elapsed) AS int8)) AS alloc_per_sec,
  buffers_backend_fsync as backend_sync
FROM
  (
  select 
  set,scale,tests.test,clients,round(tps) as tps,
  start_time,
  end_time -  start_time as elapsed,  
  checkpoints_timed,
  checkpoints_req,
  buffers_checkpoint,
  buffers_clean,
  buffers_backend,
  buffers_alloc,
  buffers_backend_fsync,
  (SELECT cast(current_setting('block_size') AS int8)) AS block_size
from test_bgwriter right join tests on tests.test=test_bgwriter.test WHERE NOT end_time is NULL
) raw
WHERE (checkpoints_timed + checkpoints_req)>0
order by scale,set,clients,test;

