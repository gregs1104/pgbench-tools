EXPLAIN (ANALYZE ON, BUFFERS ON) SELECT max(sourceline) FROM settings_loop WHERE name='shared_buffers';
