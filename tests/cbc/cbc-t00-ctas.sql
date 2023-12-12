\set SIZEGB :scale
DROP TABLE IF EXISTS settings_loop;
CREATE TABLE settings_loop AS SELECT gs.x AS seq,pgs.*
  FROM generate_series(0, :SIZEGB * 12500,1) gs(x)
  LEFT JOIN pg_settings pgs ON (true);
