WITH
best AS
  (SELECT
    cpu,server_ver,conn,script,clients,tps,hours,nodes,nodes_kips,fsync,wal_level,max_wal_gb,db_gb,
      wal_mbps, avg_write_mbps, max_write_mbps, avg_read_mbps, max_read_mbps,
    ROW_NUMBER()
    OVER(
        PARTITION BY server_ver,script,conn,nodes,fsync,wal_level,max_wal_gb
        ORDER BY nodes_kips DESC
    )  AS r
    FROM submission
  )
SELECT
    cpu,substring(server_ver,1,16) AS server_version,conn,script,clients,tps,hours,nodes,nodes_kips,fsync,wal_level,max_wal_gb,
      wal_mbps, avg_write_mbps, max_write_mbps, avg_read_mbps, max_read_mbps    
FROM best WHERE r=1
ORDER BY nodes DESC,nodes_kips DESC,script,db_gb;
