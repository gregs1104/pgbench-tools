\timing on
\set ECHO queries
CREATE TABLE settings_loop AS SELECT gs.x AS seq,pgs.* FROM generate_series(0,20 * 12500,1) gs(x) LEFT JOIN pg_settings pgs ON (true);
VACUUM (FREEZE ON, ANALYZE ON, VERBOSE ON) settings_loop;
CREATE INDEX by_name ON settings_loop (name);
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT count(*) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT count(*) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT count(*) FROM settings_loop WHERE seq<125000 LIMIT 1000;
CLUSTER verbose settings_loop USING by_name;
ANALYZE settings_loop;
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT count(*) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT count(*) FROM settings_loop WHERE name='shared_buffers';
