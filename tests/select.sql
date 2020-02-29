\set naccounts 100000 * :scale
\set aid random(1, 100000 * :naccounts)
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
