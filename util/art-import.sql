\set content `cat results.json`
-- Assume latest test by start time gets the update.
-- end_time isn't used because it's not set on failed runs.
UPDATE tests SET artifacts=:'content' 
FROM 
(SELECT server,test
 FROM tests 
 ORDER BY start_time DESC LIMIT 1
) AS t1 
WHERE tests.test=t1.test AND tests.server=t1.server;
