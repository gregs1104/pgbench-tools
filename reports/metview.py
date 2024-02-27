#!/usr/bin/env python3

"""
metview.py generates metrics graphs out of a pgbench-tools benchmark results
database.  This is the successor to the osm-metrics.py example code.

This code is at rough works for me quality with a minimal UI.
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
import argparse

def query_multimet(options):
    server=options['server']
    test=options['test']

    diskdevs=["sda","sda"] # gp2/3

    server_label = server
    col='collected'
    dbagg='second'

    # TODO Use SQL proof parameter substitution here instead of Python's
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

# TODO Turn each of these metric set groups into their own function
def metric_set_groups(options):
    server=options['server']
    test=options['test']

    view=['min_schedule_lag_ms','avg_schedule_lag_ms','max_schedule_lag_ms']
    view_label='Schedule Lag Latency'
    ylabel="Lag"

    view=['min_latency','max_latency','avg_latency']
    ylabel="Latency (ms)"
    #view_label='Latency '+cpu+" "+test
    view_label='Latency '+str(test)

    view=('Dirty')
    view_label='Dirty'
    ylabel="Dirty"


def images_dir(options):
    base="images"
    try:
        os.mkdir(base)
    except:
        pass
    return base

def create_label(options,df):
    server=options['server']
    test=options['test']

    cpu=server
    if server=='rising':
        cpu='5950X'

    # Extract run metadata from first row
    clients=df.iloc[0]['clients']

    try:
        rate_limit=round(df.iloc[0]['rate_limit'])
    except:
        rate_limit=round(df.iloc[0]['tps'])

    db_gb=round(df.iloc[0]['db_gb'])
    script=df.iloc[0]['script'].upper()

    view_label=cpu+" "+script+" "+str(db_gb)+"GB "+str(clients)+" clients @ "+str(rate_limit)+" TPS"
    return view_label

def gen_file_name(base,view,server,test):
    unslashed=view.replace("/","-")
    name=os.path.join(base,server+"-"+str(test)+"-"+unslashed)
    return name

def graph_group(options,df):
    server=options['server']
    test=options['test']

    metrics={}
    rendered=0

    base=images_dir(options)

    plt.rcParams.update({'font.size':'18'})
    colors=('green','blue','purple')

    view=['rate']
    view_label='Rate'
    ylabel="TPS"

    view_label=create_label(options,df)

    g=df.groupby('metric')

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

            fn=gen_file_name(base,k,server,test)
            # Only save on last metric in the view list
            if rendered==(len(view)):
                plt.savefig(fn,dpi=600)  # 80 for =640x480 figures
                print("saved to '%s.png'" % fn)


def process(options,conn):
    try:
        sql=query_multimet(options)
        print(sql)
        df = pd.read_sql_query(sql, conn)
        print(df)
        graph_group(options,df)
    finally:
        conn.close()

def connect(options):
    conn_string = "host='localhost' dbname='results' user='gsmith' password='secret'"
    print("Connecting to database\n	->%s" % (conn_string))
    return psycopg2.connect(conn_string)

def parse():
    parser = argparse.ArgumentParser(description='metview.py benchmark results metrics viewer')
    parser.add_argument("test", type=int, help='Test number',nargs='?',default=4974)
    parser.add_argument("server", help="server name",nargs='?',default='rising')
    args = parser.parse_args()
    return args

if __name__ == "__main__":
    args_dict=vars(parse())
    c=connect(args_dict)
    process(args_dict,c)
