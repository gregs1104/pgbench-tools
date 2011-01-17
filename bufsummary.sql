-- Report of background write effectiveness
-- select info,testset.set,round(avg(tps)) as tps,round(10000*sum(buffers_clean) / (sum(buffers_backend)+sum(buffers_clean)))/100.0 as cleaner_pct from testset,test_bgwriter right join tests on tests.test=test_bgwriter.test where testset.set=tests.set group by testset.set,testset.info order by testset.set;

select 
  set,scale,clients,
  round(avg(tps)) as tps,
  round(avg(checkpoints_timed+checkpoints_req)) as chkpts,
  round(avg(buffers_checkpoint)) as buf_check,
  round(avg(buffers_clean)) as buf_clean,
  round(avg(buffers_backend)) as buf_backend,
  round(avg(buffers_alloc)) as buf_alloc ,
  round(avg(buffers_backend_fsync)) as backend_fsync
from test_bgwriter 
right join tests on tests.test=test_bgwriter.test 
group by scale,set,clients
order by scale,set,clients;

--select 
--  set,scale,clients,
--  round(avg(tps)) as tps,
--  round(avg(checkpoints_timed+checkpoints_req)) as chkpts,
--  round(avg(buffers_checkpoint)) as buf_check,
--  round(avg(buffers_clean)) as buf_clean,
--  round(avg(buffers_backend)) as buf_backend,
--  round(avg(buffers_alloc)) as buf_alloc 
--from test_bgwriter 
--right join tests on tests.test=test_bgwriter.test 
--group by scale,set,clients
--order by scale,set,clients;


