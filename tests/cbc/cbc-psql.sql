\set SIZEGB :scale
DROP TABLE IF EXISTS settings_loop;
SELECT name,current_setting(name) FROM pg_settings where name in ('autovacuum','shared_buffers');
SELECT pg_stat_reset();
SELECT pg_stat_statements_reset();
\timing on
\set ECHO queries
CREATE TABLE settings_loop AS SELECT gs.x AS seq,pgs.* FROM generate_series(0, :SIZEGB * 12500,1) gs(x) LEFT JOIN pg_settings pgs ON (true);
VACUUM (FREEZE ON, ANALYZE ON, VERBOSE ON) settings_loop;
CREATE INDEX by_name ON settings_loop (name);
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE seq < :SIZEGB * 6250 LIMIT :SIZEGB * 125;
CLUSTER verbose settings_loop USING by_name;
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
\timing off
\x on
SELECT pg_relation_size('settings_loop') AS "Size-Table";
SELECT pg_relation_size('by_name') AS "Size-Index";
--SELECT * FROM pg_stat_statements;
