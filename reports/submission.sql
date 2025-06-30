-- Depends on write_internals view defined in reports/write_internals.sql
DROP TABLE IF EXISTS submission_author;
CREATE TABLE submission_author (
  submitter text,
  email text,
  affiliation text
);

INSERT INTO submission_author(submitter,email,affiliation) VALUES
  ('Greg Smith','greg.smith@crunchydata.com','Crunchy Data');

DROP TABLE IF EXISTS submission;
-- TODO Finished table needs a serial number for each submission
CREATE TABLE submission AS
SELECT
  submitter,affiliation,
  write_internals.*
FROM write_internals,submission_author
LIMIT 0;

INSERT INTO submission (
    submitter, affiliation,
    ref_info, run, cpu, mem_gb, disk, os_rel, conn,
    script, set, server_ver, clients, scale, nodes, db_gb,
    tps, avg_latency, percentile_90_latency, max_latency, rate_limit, hours, nodes_kips,
    shared_gb, maint_gb, max_wal_gb, fsync, wal_level, timeout,
    timed_pct, chkp_mins, chkp_mbph, clean_mbph, backend_mbph, cleaned_pct, max_dirty,
    hit_pct, hit_mbps, read_mbps, wal_mbps,
    avg_write_mbps, max_write_mbps, avg_read_mbps, max_read_mbps
)
SELECT
  submitter,affiliation,
  write_internals.*
FROM write_internals,submission_author;
