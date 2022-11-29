#!/usr/bin/env python3
"""
Basic test plotter program that shows how much I/O a single benchmark test run
took.  This one is tweaked for the Open Street Map data loading set, but the
approach is mostly generic Pandas/SQL integration.  Committing in its raw
form because it's the code used to generate graphs in one of my presentations.
"""
import os
import psycopg2
import psycopg2.extras

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib

# Not a UI yet, just modify this section to point at a single test to plot
server='siren'
test='177'
diskdev="nvme1n1" # siren
script='init'  # Currently commented out in the SQL

# General config options
server_label = server
col='collected'
dbagg='minute'

sql="""
SELECT
  --test_metrics_data.server,
  --script,
  --scale,clients,
  --round(tps) AS tps,
  metric,
  date_trunc('%s',collected) AS collected,
  --min(value) AS min,
  avg(value) AS avg,
  max(value) AS max 
FROM test_metrics_data,tests
WHERE 
  test_metrics_data.server=tests.server AND
  test_metrics_data.test=tests.test AND
  --script='%s' AND
  test_metrics_data.test=%s AND
  test_metrics_data.server='%s' AND
  metric IN (
      --'rate','avg_latency','min_latency','max_latency',
      --'bi','bo'
      --'id','wa',
      'Dirty',
      '%s_%%util',
      '%s_rMB/s','%s_wMB/s'
      )
GROUP BY test_metrics_data.server,script,scale,clients,tps,metric,date_trunc('%s',collected)
ORDER BY test_metrics_data.server,script,scale,clients,tps,metric,date_trunc('%s',collected)
;""" % (dbagg,script,test,server,diskdev,diskdev,diskdev,dbagg,dbagg)

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
    metrics={}
    plt.rcParams.update({'font.size':'18'})
    if False:
        matplotlib.style.use('seaborn-whitegrid')
        plt.rcParams.update({'font.family':'fantasy'})

    base="images"
    try:
        os.mkdir(base)
    except:
        pass

    df=main()
    df.set_index(col, inplace=True)
    print(df)    
    g=df.groupby('metric')

    for k,v in g:
        print("Processing",k)
        print(v)
        metrics[k]=v

        ylabel="Transfer rate MB/s"
        if k=='Dirty':
            # Linux mem figures are in KB, rescale to GB
            v['avg'] /= (1024 * 1024)
            v['max'] /= (1024 * 1024)
            print("Reprocessed")
            print(v)
            ylabel="Dirty Memory GB"

        ax=v.plot(title=k,figsize=(8,6),color=['blue','purple'])
        ax.set_ylabel(ylabel)

        unslashed=k.replace("/","-")
        fn=os.path.join(base,server+'-'+unslashed)
        ax.figure.savefig(fn)
        print("saved to '%s.png'" % fn)

    combined=pd.merge_asof(metrics[diskdev+'_rMB/s'], metrics[diskdev+'_wMB/s'], 
                           direction="nearest",on="collected",
                           suffixes=('_read', '_write'))
    combined['Average'] = combined[['avg_read','avg_write']].sum(axis=1)
    combined['Max'] = combined[['max_read','max_write']].sum(axis=1)

    combined.set_index('collected',inplace=True)
    print("Merged")
    print(combined)

    combined_ax=combined[['Average','Max']].plot(
                    figsize=(8,6),
                    title="Combined Read+Write Speed - OSM Load",
                    ylabel="Transfer rate MB/s",
                    xlabel='',
#                    xlabel='Time Collected',
#                    fontname="Brush Script MT"
#                    fontsize=18
#                    legend='reverse',
                    color=['blue','purple']
                    )
    rw=os.path.join(base,server+'-'+'read-write')
    combined_ax.figure.savefig(rw)
    print("saved to '%s.png'" % rw)
    