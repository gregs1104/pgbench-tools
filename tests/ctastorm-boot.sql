DROP TABLE IF EXISTS sl_b;
CREATE TABLE sl_b AS SELECT gs.x AS seq,pgs.* FROM generate_series(0, :scale * 12500,1) gs(x) LEFT JOIN pg_settings pgs ON (true);
VACUUM (FREEZE ON, ANALYZE ON, VERBOSE ON) sl_b;
