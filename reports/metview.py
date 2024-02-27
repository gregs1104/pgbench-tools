#!/usr/bin/env python3

"""
metview.py generates metrics graphs out of a pgbench-tools benchmark results
database.  This is the successor to the osm-metrics.py example code.

This code is at rough works for me quality with a minimal UI.
Committing and releasing in this state as a safety net to enable
refactoring toward a proper CLI tool.
"""

import argparse
import os
import matplotlib.pyplot as plt
import matplotlib.image as image
from matplotlib.offsetbox import (OffsetImage, AnnotationBbox)
import pandas as pd
import psycopg2
import psycopg2.extras

def connect(options):
    # TODO Put database connection parameters into options
    conn_string = "host='localhost' dbname='results' user='gsmith' password='secret'"
    print("Connecting to database\n	->%s" % (conn_string))
    return psycopg2.connect(conn_string)

def parse():
    parser = argparse.ArgumentParser(description='metview.py benchmark results metrics viewer')
    parser.add_argument("server", help="server name",nargs='?',default='rising')
    parser.add_argument("test", type=int, help='Test number',nargs='?',default=4974)
    return vars(parser.parse_args())

# TODO Move output directory to results/server/test/images
def images_dir(options):
    base="images"
    try:
        os.mkdir(base)
    except:
        # TODO catch real errors, continue to ignore directory already exists error
        pass
    return base

def gen_label(options,df):
    server=options['server']
    test=options['test']

    cpu=server
    # TODO Lookup CPU info from server table
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

# TODO Create alternate query that includes all the metrics
def query_multi_met(options):
    server=options['server']
    test=options['test']
    # TODO determine dbagg based on length of test run
    dbagg='second'

    # TODO Use SQL injection proof parameter substitution here instead of Python's
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
          'Dirty'
          )
    GROUP BY test_metrics_data.server,script,scale,clients,rate_limit,tps,round(dbsize / (1024*1024*1024)),metric,date_trunc('%s',collected)
    ORDER BY test_metrics_data.server,script,scale,clients,rate_limit,round(dbsize / (1024*1024*1024)),metric,date_trunc('%s',collected)
    ;""" % (dbagg,test,server,dbagg,dbagg)
    return sql

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

    view_label=gen_label(options,df)

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

            fn=gen_file_name(base,k,server,test)
            # Only save on last metric in the view list
            if rendered==(len(view)):
                # TODO Bottom part of graph is strangely cut off?  Rotation issue?
                plt.savefig(fn,dpi=600)  # 80 for =640x480 figures
                print("saved to '%s.png'" % fn)

                ab = AnnotationBbox(im, (1, 0), frameon=False, xycoords='axes fraction',
                     box_alignment=(0.55,1.85))
                ax.add_artist(ab)
                plt.savefig(fn+"-logo",dpi=600)  # 80 for =640x480 figures
                print("saved to '%s-logo.png'" % fn)

# TODO add options to change which query and graph function are called
def graph(options,conn):
    try:
        sql=query_multi_met(options)
        print(sql)
        df = pd.read_sql_query(sql, conn)
        print(df)
        graph_group(options,df)
    finally:
        conn.close()

def gen_graphs():
    args_dict=parse()
    c=connect(args_dict)
    graph(args_dict,c)

if __name__ == "__main__":
    gen_graphs()
