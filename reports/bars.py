#!/usr/bin/env python3
import os
import psycopg2
import psycopg2.extras

import pandas as pd
import matplotlib.pyplot as plt
import mplfinance as mpf

server='rising'
server_label = server
col='collected'

script='nobranch';
dbagg='second'
sql="""
SELECT
  test_metrics_data.server,
  script,
  scale,clients,
  round(tps) AS tps,
  metric,
  date_trunc('%s',collected) AS collected,
  min(value) AS min,
  CASE 
    WHEN avg(value) > 100 THEN round(avg(value))
    WHEN avg(value) > 10 THEN round(avg(value)::NUMERIC,1)
    WHEN avg(value) > 1 THEN round(avg(value)::NUMERIC,2)
    ELSE round(avg(value)::NUMERIC,3)
  END AS avg,
  max(value) AS max 
FROM test_metrics_data,tests
WHERE 
  test_metrics_data.server=tests.server AND
  test_metrics_data.test=tests.test AND
  script='%s' AND
  test_metrics_data.test=3833 AND
  test_metrics_data.server='rising' AND
  metric IN ('rate','avg_latency','min_latency','max_latency','id','wa','Dirty','nvme0n1_%%util','nvme0n1_rMB/s','nvme0n1_wMB/s')
GROUP BY test_metrics_data.server,script,scale,clients,tps,metric,date_trunc('%s',collected)
ORDER BY test_metrics_data.server,script,scale,clients,tps,metric,date_trunc('%s',collected)
;""" % (dbagg,script,dbagg,dbagg)

def main():
    conn_string = "host='localhost' dbname='results' user='gsmith' password='secret'"
    print("Connecting to database\n	->%s" % (conn_string))
    conn = psycopg2.connect(conn_string)

    try:
        print(sql)
        df = pd.read_sql_query(sql, conn)
        return df
    finally:
        conn.close()

if __name__ == "__main__":
    # TODO Create this directory if it doesn't exist
    base="images"

    df=main()
    df.set_index(col, inplace=True)

    df.rename(columns={'avg':'Open'},inplace=True)
    df.rename(columns={'max':'High'},inplace=True)
    df.rename(columns={'min':'Low'},inplace=True)
    df['Close'] = df['Open']
    df['Close'] = df.loc[:, 'Open']

    g=df.groupby('metric')

    print(g)
    fig=plt.figure();
    ax=fig.add_subplot(1,1,1)

    for k,v in g:
        print("Processing",k)

        v = v.resample('15S').agg(
            {'Open'  :'first',
             'High'  :'max',
             'Low'   :'min',
             'Close' :'last'
            })
        print(v)

        unslashed=k.replace("/","-")
        fn=os.path.join(base,unslashed)

        mpf.plot(v,type='ohlc',ylabel=k,savefig=fn,mav=5)
        mpf.plot(v,type='ohlc',ylabel=k,mav=5)

        print("saved to '%s.png'" % fn)
