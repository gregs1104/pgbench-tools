DROP TABLE timing;

CREATE TABLE timing(
  ts timestamp,
  filenum int, 
  latency numeric(9,3),
  test int
  );

CREATE INDEX idx_timing_test on timing(test,ts);

DROP TABLE tests;

CREATE TABLE tests(
  test serial,
  set serial,
  scale int,
  dbsize int8,
  start_time timestamp default now(),
  end_time timestamp default null,
  tps decimal default 0,
  script text,
  clients int,
  workers int,
  trans int,
  avg_latency float,
  max_latency float,
  percentile_90_latency float
  );

DROP TABLE testset;

CREATE TABLE testset(
  set serial,
  info text
  );

INSERT INTO testset (info) VALUES ('');

DROP TABLE test_bgwriter;

CREATE TABLE test_bgwriter(
  test int,
  checkpoints_timed int,
  checkpoints_req int,
  buffers_checkpoint int,
  buffers_clean int,
  maxwritten_clean int,
  buffers_backend int,
  buffers_alloc int,
  buffers_backend_fsync int
);
