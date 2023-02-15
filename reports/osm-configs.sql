  WITH key_range AS
  (
  SELECT server,test FROM tests WHERE
    -- server='dash' AND 
    script LIKE 'osm2pgsql-%'
  )
  ,
  test_keys AS
  (SELECT
    oldt.server,
    oldt.test,
    (SELECT test FROM tests t WHERE t.server=oldt.server AND t.script=oldt.script AND t.test>oldt.test ORDER BY t.test - oldt.test LIMIT 1) AS next
  FROM tests oldt
  GROUP BY oldt.test,oldt.script,oldt.server
  ),
  changed AS (
  SELECT
    new.test AS test,old.name,old.setting AS old,new.setting AS new
  FROM key_range kr JOIN
    test_keys tk
  ON (kr.server=tk.server AND kr.test=tk.test),
   test_settings old
    JOIN test_settings new ON old.name=new.name AND old.server=new.server
    JOIN tests oldt ON old.test=oldt.test AND old.server=oldt.server
  WHERE
    kr.server=old.server AND kr.test=old.test AND
    old.server=tk.server AND old.test=tk.test AND
    new.server=tk.server AND new.test=tk.next AND
    old.setting != new.setting
  GROUP BY new.test,old.server,old.name,old.setting,new.name,new.setting,new.test,oldt.test,oldt.script,oldt.server)
  SELECT array_to_string(array_agg(test),'-') AS test,array_to_string(array_agg(name || ':' || old || '->' || new),';') AS settings  FROM changed GROUP BY test;

