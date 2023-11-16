\set SIZEGB :scale
DROP TABLE settings_loop;
CREATE TABLE settings_loop AS SELECT gs.x AS seq,pgs.* FROM generate_series(0, :SIZEGB * 12500,1) gs(x) LEFT JOIN pg_settings pgs ON (true);
VACUUM (FREEZE ON, ANALYZE ON, VERBOSE ON) settings_loop;
CREATE INDEX by_name ON settings_loop (name);
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE seq < :SIZEGB * 6250 LIMIT :SIZEGB * 125;
CLUSTER verbose settings_loop USING by_name;
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
