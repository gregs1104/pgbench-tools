\set naccounts 100000 * :scale
\setrandom aid 1 :naccounts
SELECT abalance FROM pgbench_accounts WHERE aid = :aid;
