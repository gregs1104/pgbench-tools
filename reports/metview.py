#!/usr/bin/env python3

"""
metview.py generates metrics graphs out of a pgbench-tools benchmark results
database.  This is the successor to the osm-metrics.py example code.

This code is at rough works for me quality without a working UI yet.
It's filled with debris related to an WIP presentation too.
Committing and releasing in this state as a safety net to enable a
major refactoring to make this a proper CLI tool.
"""

import os
import sys
import psycopg2
import psycopg2.extras
from datetime import datetime

import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
import matplotlib.image as image
from matplotlib.offsetbox import (OffsetImage, AnnotationBbox)

def examples():
    server='gp2'
    test='2'
    server='gp3'
    test='2'

    server='gp3'
    test='8'
    server='gp2'
    test='8'

    server='rising'

    # Perfect results
    test='4902' # 4000 TPS @ 1GB 4 clients, low latency
    test='4909' # 38400 TPS @ 1GB, low latency
    test='4905' # 49600 TPS @ 1GB, low latency
    test='4910' # 68800 TPS @ 1GB, low latency
    test='4911' # 99200 TPS @ 1GB, overheat
    test='4932' # 128000 TPS @1GB low latency

    test='4968' # 32000 perfect performance with 500GB DB
    test='4915' # 76800 TPS @ 1GB perfect low latency
    test='4914' # 16000 TPS @ 1GB perfect very low latency

    test='4390' # INSERT 1GB 64 @ 12800 smooth

    # Latency falls aoart
    test='4921' # 153000 TPS @1GB, shows CPU overheating making latency escalate at the end
    test='4916' # 137600 TPS @ 1GB late overhead drift
    test='5166' # 64000 TPS at 151GB, slow overheat even though it seems it can do 130000
    test='5214' # 64000 TPS at 200GB, just starting to overheat at the end
    test='4944' # 2000 TPS @ 500GB very light overhead at end
    test='4974' # 64000 TPS overheading with 500GB real disk I/O

    # Max latency constantly falling apart
    test='4945' # 9600 TPS @ 500GB constant latency misses
    test='4917' # 198400 TPS  @ 1GB constant misses

    test='8160' # Weird driver cache INSERT results
    test='8204' # Checkpoint FPW spike trashes performance
    test='9790' # fixed rate mesz

    server='gp3'
    test=327

    server='gp2'
    test=417  # 95% latency is just 25ms; just needs trimming to be perfect
    test=409 # near breakdown @ 1600
    test=419 # near breakdown @ 1920
    test=418 # near breakdown @ 1920

    test=385 # serious breakdown

    server='rising'
    test=4393 # high rate INSERT, trimmable edge issues
    test=4392 # high rate INSERT, drop glitch near end
    test=4387 # high rate INSERT, perfectly smooth, saved before schedule lag feature added

def query():
    server='rising'
    test='4974' # 64000 TPS overheading with 500GB real disk I/O

    diskdevs=["sda","sda"] # gp2/3

    server_label = server
    col='collected'
    dbagg='second'

    sql="""
    SELECT
      --test_metrics_data.server,
      script,
      tps,
      --scale,
      round(dbsize / (1024*1024*1024)) as db_gb,
      clients,
      rate_limit,
      metric,
      date_trunc('%s',collected) AS collected,
      --min(value) AS min,
      avg(value) AS avg,
      max(value) AS max
    FROM test_metrics_data,tests
    WHERE
      test_metrics_data.server=tests.server AND
      test_metrics_data.test=tests.test AND
      test_metrics_data.test=%s AND
      test_metrics_data.server='%s' AND
      metric IN (
            'rate','avg_latency','min_latency','max_latency',
            'min_schedule_lag_ms','avg_schedule_lag_ms','max_schedule_lag_ms',
            'pg_clients_active','pg_clients_idle','pg_db_size','pg_max_query_runtime_sec',
    --      'bi','bo'
    --      'id','wa',
          'Dirty'
    --      '%s_rMB/s',
    --      '%s_wMB/s',
    --      '%s_rMB/s',
    --      '%s_wMB/s',
    --      '%s_MB/s',
    --      '%s_MB/s'
          )
    GROUP BY test_metrics_data.server,script,scale,clients,rate_limit,tps,round(dbsize / (1024*1024*1024)),metric,date_trunc('%s',collected)
    ORDER BY test_metrics_data.server,script,scale,clients,rate_limit,round(dbsize / (1024*1024*1024)),metric,date_trunc('%s',collected)
    ;""" % (dbagg,test,server,
        # Linux R/W
        diskdevs[0],diskdevs[0],
        diskdevs[1],diskdevs[1],
        # Mac total
        diskdevs[0],diskdevs[1],
        dbagg,dbagg)

    return sql

def graph(df):
    server='rising'
    test='4974'

    cpu=server
    if server=='rising':
        cpu='5950X'

    metrics={}
    plt.rcParams.update({'font.size':'18'})

    base="images"
    try:
        os.mkdir(base)
    except:
        pass

    g=df.groupby('metric')

    #
    view=['min_schedule_lag_ms','avg_schedule_lag_ms','max_schedule_lag_ms']
    view_label='Schedule Lag Latency'
    ylabel="Lag"

    view=('Dirty')
    view_label='Dirty'
    ylabel="Dirty"

    view=['rate']
    view_label='Rate'
    ylabel="TPS"


    view=['min_latency','max_latency','avg_latency']
    ylabel="Latency (ms)"
    #view_label='Latency '+cpu+" "+test
    view_label='Latency '+str(test)

    view=['rate']
    view_label='Rate'
    ylabel="TPS"


    # Extract run metadata from first row
    clients=df.iloc[0]['clients']

    try:
        rate_limit=round(df.iloc[0]['rate_limit'])
    except:
        rate_limit=round(df.iloc[0]['tps'])

    db_gb=round(df.iloc[0]['db_gb'])
    script=df.iloc[0]['script'].upper()

    view_label=cpu+" "+script+" "+str(db_gb)+"GB "+str(clients)+" clients @ "+str(rate_limit)+" TPS"
    rendered=0

    colors=('green','blue','purple')

    for k,v in g:
        print("Processing",k)
        print(v)
        metrics[k]=v
        v.set_index('collected',inplace=True)

        metrics[k]=metrics[k].drop(columns=['avg','metric'])
        metrics[k].rename(columns={'max': k}, inplace=True)

        file="Color Horizontal.jpg"
        logo=image.imread(file)
        im = OffsetImage(logo, zoom=.03)

        if k in view:
            rendered=rendered+1

            if k=='Dirty':
                # Linux mem figures are in KB, rescale
                v['avg'] /= (1024 )
                v['max'] /= (1024)
                print("Reprocessed")
                print(v)
                ylabel="Dirty Memory MB"

            ax=v['avg'].plot(rot=90,title=view_label,figsize=(8,6))
            #,color=colors[rendered])

            # This just shows avg/avg/avg on legend
            # ax.legend()

            ax.set_ylabel(ylabel)
            ax.grid(True,which='both')
            ab = AnnotationBbox(im, (1, 0), frameon=False, xycoords='axes fraction',
                 box_alignment=(0.55,1.85))
            ax.add_artist(ab)

            unslashed=k.replace("/","-")
            fn=os.path.join(base,server+"-"+str(test)+"-"+unslashed)
            # Only save on last metric in the view list
            if rendered==(len(view)):
                plt.savefig(fn,dpi=600)  # 80 for =640x480 figures
                print("saved to '%s.png'" % fn)


def connect():
    conn_string = "host='localhost' dbname='results' user='gsmith' password='secret'"
    print("Connecting to database\n	->%s" % (conn_string))
    conn = psycopg2.connect(conn_string)
    try:
        sql=query()
        print(sql)
        df = pd.read_sql_query(sql, conn)
        print(df)
        graph(df)
    finally:
        conn.close()

if __name__ == "__main__":
    connect()

