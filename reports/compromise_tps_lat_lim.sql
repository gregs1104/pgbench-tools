SELECT
  tps.server,tps.set,t.info,tps.script,tps.scale,tps.clients,tps.workers,
  tps.tps as tps,
  --lat.set,lat.script,lat.scale,lat.clients,lat.workers,
  lat.p90_latency 
FROM
testset t, 
(
	SELECT
	  server,set,script,scale,clients,workers,
	  round(tps) AS tps
	FROM
	(
	  SELECT
	    server,set,script,scale,clients,workers,
	    max(tps) AS tps
	  FROM tests
	  GROUP BY server,set,script,scale,clients,workers
	) as g1
) AS tps,
--ORDER BY tps DESC 
LATERAL (
	SELECT
	  server,set,script,scale,clients,workers,
	  p90_latency
	FROM
	(
	 SELECT
	    server,set,script,scale,clients,workers,
	    min(percentile_90_latency) AS p90_latency
	  FROM tests
	  WHERE
	        percentile_90_latency IS NOT NULL
	  GROUP BY server,set,script,scale,clients,workers
	) AS g2
)  lat 
WHERE 
	lat.set = tps.set
AND     lat.server=tps.server
AND     lat.scale=tps.scale
AND     lat.clients=tps.clients
AND     lat.workers=tps.workers
AND     t.set=lat.set
AND     lat.p90_latency <=15 AND     tps.tps >=700
AND     tps.scale>=1000
ORDER BY tps.tps DESC, lat.p90_latency LIMIT 20
