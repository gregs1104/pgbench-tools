\set SIZEGB :scale
CREATE EXTENSION pg_stat_statements;
DROP TABLE IF EXISTS sl_b;
SELECT pg_stat_reset();
SELECT pg_stat_statements_reset();
\timing on
\set ECHO queries
CREATE TABLE sl_b AS SELECT gs.x AS seq,pgs.* FROM generate_series(0, :SIZEGB * 12500,1) gs(x) LEFT JOIN pg_settings pgs ON (true);
VACUUM (FREEZE ON, ANALYZE ON, VERBOSE ON) sl_b;
