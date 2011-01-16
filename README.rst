pgbench-tools setup
===================

* Create databases for your test and for the results::

    createdb results
    createdb pgbench

  *  Both databases can be the same, but there may be more shared_buffers
     cache churn in that case.  Some amount of cache disruption
     is unavoidable unless the result database is remote, because
     of the OS cache.  The recommended and default configuration
     is to have a pgbench database and a results database.  This also
     keeps the size of the result dataset from being included in the
     total database size figure recorded by the test.

* Initialize the results database by executing::

    psql -f init/resultdb.sql -d results

  Make sure to reference the correct database.
  This will create a default test set entry with a blank description.
  You may want to rename that using something like this::

    psql -c "UPDATE testset SET info='better name' WHERE set=1" -d results

Running tests
=============

* Edit the config file to run the tests you want

* Execute::

    ./runset

  In order to execute all the tests

Results
=======

* You can check results even as the test is running with::

    psql -d results -f report.sql

  This is unlikely to disrupte the test results very much unless you've
  run an enormous number of tests already.

* Other useful reports you can run include:
   * fastest.sql
   * summary.sql
   * bufreport.sql
   * bufsummary.sql
 
* Once the tests are done, the results/ directory will include
  a HTML subdirectory for each test giving its results,
  in addition to the summary information in the results database.

* The results directory will also include its own index HTML file that
  shows summary information and plots for all the tests.

* If you manually adjust the test result database, you can
  then manually regenerate the summary graphs by running::

    ./webreport

Version compatibility
=====================

The default configuration now aims to support the pgbench that ships with
PostgreSQL 8.4 and later versions, which uses names such as "pgbench_accounts"
for its tables.  There are commented out settings on the config file that
show what changes need to be made in order to make the program compatible
with PostgreSQL 8.3, where the names were like "accounts" instead.

Support for PostgreSQL versions before 8.3 is not possible, because a
change was made to the pgbench client in that version that is needed
by the program to work properly.  It is possible to use the PostgreSQL 8.3
pgbench client against a newer database server, or to copy the pgbench.c
program from 8.3 into a 8.2 source code build and use it instead (with
some fixes--it won't compile unless you comment out code that refers to
optional newer features added in 8.3).

Multiple worker support
-----------------------

Starting in PostgreSQL 9.0, pgbench allows splitting up the work pgbench
does into multiple worker threads or processes (which depends on whether
the database client libraries haves been compiled with thread-safe 
behavior or not).  

This feature is extremely valuable, as it's likely to give at least
a 15% speedup on common hardware.  And it can more than double throughput
on operating systems that are particularly hostile to running the
pgbench client.  One known source of this problem is Linux kernels
using the Completely Fair Scheduler introduced in 2.6.23,
which does not schedule the pgbench program very well when it's connecting
to the database using the default method, Unix-domain sockets.

(Note that pgbench-tools doesn't suffer greatly from this problem itself, as
it connects over TCP/IP using the "-H" parameter.  Manual pgbench runs that
do not specify a host, and therefore connect via a local socket can be
extremely slow on recent Linux kernels.)

Taking advantage of this feature is done in pgbench-tools by increasing the
MAX_WORKERS setting in the configuration file.  It defaults to blank, which
avoids using this feature altogether--therefore remaining
compatible with PostgreSQL/pgbench versions before this capability was added.

When using multiple workers, each must be allocated an equal number of
clients.  That means that client counts that are not a multiple of the
worker count will result in pgbench not running at all.

According, if you set MAX_WORKERS to a number to enable this capability,
pgbench-tools picks the maximum integer of that value or lower that the
client count is evenly divisible by.  For example, if MAX_WORKERS is 4,
running with 8 clients will use 4 workers, while 9 clients will shift
downward to 3 workers as the best option.

A reasonable setting for MAX_WORKERS is the number of physical cores
on the server, typically giving best performance.  And when using this feature,
it's better to tweak test client counts toward ones that are divisible by as
many factors as possible.  For example, if you wanted approximately 15
clients, it would be best to use 16, allowing worker counts of 2, 4, or 8, 
all likely to match common core counts.  Second choice would be 14,
compatible with 2 workers.  Third is 15, which would allow 3 workers--not
improving upon a single worker on common dual-core systems.  The worst
choices would be 13 or 17 clients, which are prime and therefore cannot
be usefully allocated more than one worker on common hardware.

Known issues
============

* If running tests against non-pgbench tables, the database scale
  will not be detected correctly yet

* On Solaris, where the benchwarmer script calls tail it may need
  to use /usr/xpg4/bin/tail instead

Planned features
================

* Currently none of the graphs break their display down based on the
  test set.  Each set could be mapped into a separate data set, and
  therefore the graph used to compare sets.

* The client+scale data table used to generate the 3D report would be
  useful to generate in tabular text format as well.

Documentation
=============

The documentation ``README.rst`` for the program is in ReST markup.  Tools
that operate on ReST can be used to make versions of it formatted
for other purposes, such as rst2html to make a HTML version.

Contact
=======

The project is hosted at https://github.com/gregs1104/pgbench-tools
and is also a PostgreSQL project at http://git.postgresql.org/git/pgbench-tools.git
or http://git.postgresql.org/gitweb

If you have any hints, changes or improvements, please contact:

 * Greg Smith gsmith@gregsmith.com

Credits
=======

Copyright (c) 2007-2011, Gregory Smith
All rights reserved.
See COPYRIGHT file for full license details

