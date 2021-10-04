\set range 134 * :multiplier
\set limit 100000 * :scale
\set limit :limit - :range
\set aid random(1, :limit)
SELECT aid,abalance FROM pgbench_accounts WHERE aid >= :aid AND aid < (:aid + :range::bigint);

