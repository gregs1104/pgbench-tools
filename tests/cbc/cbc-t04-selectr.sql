\set SIZEGB :scale
EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE seq < :SIZEGB * 6250 LIMIT :SIZEGB * 125;
