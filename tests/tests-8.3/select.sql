\set naccounts 100000 * :scale
\setrandom aid 1 :naccounts
SELECT abalance FROM accounts WHERE aid = :aid;
