# Complete Block Check:  PostgreSQL Storage Benchmark

Complete Block Check (CBC) stresses multiple major parts of block I/O
in the database using synthetic test data.  It was developed against
PostgreSQL 15 and uses CREATE TABLE AS, VACUUM, CREATE INDEX, and
CLUSTER.  A simple but difficult to execute query is run along the way,
initially with a Sequential Scan.  By the end that query should use a
quick indexed lookup.

# Intro

I’ve evaluated a bunch of benchmark ideas that stress storage before,
but usually using `pgbench` to generate the test database and workload.
When I was working on loading the Open Street Map data, I noticed that
`CREATE TABLE AS` is really fast now, fast enough to be a load generator
if you have a wide table to work with.  And there is a wide table in the
system views!  `pg_settings` has a lot of columns of all sorts of data
types, a lot more variation than the `pgbench` tables ever did. 

# Example output

Here's a lightly formatted example via the collector script.
Hardware is AMD 7700X processor, 128GB RAM, SK41 2TB SSD; times
are in milliseconds, sizes in bytes, disk rates in MB/s:

	SERVER        siren
	CREATE_TABLE  33116.420
	VACUUM        9293.740
	CREATE_INDEX  36316.109
	SELECT_u1     832.447
	SELECT_b      209.221
	SELECT_r      2443.925
	CLUSTER       87918.913
	SELECT_u2     81.555
	SELECT_c      80.997
	SIZE_T        21837168640
	SIZE_I        636223488
	READ_RATE     2277.521
	WRITE_RATE    2279.278

The READ/WRITE_RATE figures come from the VACUUM command and
only apply to that line.  During benchmark development, that command
was frequently the highest rate step.  PostgreSQL 15 introduced monitoring
that rate in VACUUM's text output, making it easy to include here.

# Usage

You can run a CBC in command line `psql` like this:

	psql -d $DB -v scale=$SIZEDB -ef cbc-psql.sql > $OUTBASE.log 2>&1

For testing in a browser `psql` like the Crunchy PostgreSQL Playground,
you just have to put the scale number in manually instead:

	\set SIZEGB 1

# Collector

The program includes a standalone results collector script named
`cbc` that runs the benchmark and saves to a text file in results/ directory.

Inputs:

* Database size in GB.  Defaults to 20.

Output is in a key/value style.

# pgbench driver

The workload runs in pgbench utilizing its scale setting.  To make
this compatible with using pgbench-tools to monitor each step, I've
split the pieces up into individual files to allow executing by multiple
clients.  Currently that includes:

	cbc-t00-ctas.sql	cbc-t01-vacuum.sql	cbc-t02-index.sql
	cbc-t03-select-max.sql	cbc-t04-selectr.sql	cbc-t05-cluster.sql

Here's a full run of the benchmark using `pgbench` to monitor each step:

	createdb cbc
	psql -d cbc -c "DROP TABLE settings_loop"
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t00-ctas.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t01-vacuum.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t02-index.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t03-select-max.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t03-select-max.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t04-selectr.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t05-cluster.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t03-select-max.sql cbc
	pgbench -n -t 1 -c 1 -s 20 -f cbc-t03-select-max.sql cbc

Many of these steps can only run once.  The main SELECT query can
of course be run in parallel.  This example starts 4 clients running
it for 60 seconds:

	pgbench -n -T 60 -c 4 -s 20 -f cbc-t03-select-max.sql cbc

# Credits

`cbc` was developed by Greg Smith as part of the PostgreSQL regression testing
effort at Crunchy Data.  The scripts are being initially released as part of
the `pgbench-tools `repository.

# Dedication

Greg's benchmark lab names its many servers after favorite songs.
The AMD AM5 7700X system used for this development was named for
"Siren Song" on the 1993 Alan Parsons Album `Try Anything Once`,
written by Alan Parsons Project guitarist Ian Bairnson with
composer Frank Musker.  Ian passed away in April of 2023 just
as `cbc` validation started on siren.  Ian was Greg's friend and
he went out at the top!  Ian played on Kate Bush's first hit, and her
"Running Up That Hill (A Deal with God)" (with APP drummer
Stuart Elliott) featured prominently in Season 4 of the hit show
`Stranger Things`.  That brought the song smashing back to the radio
internationally and filled Ian's last year with press coverage.
