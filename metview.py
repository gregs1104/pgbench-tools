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

# Define what categories various metrics are in
rates=("rate")
latencies=("avg_latency","max_latency ","min_latency")
lags=("min_schedule_lag_ms","avg_schedule_lag_ms","max_schedule_lag_ms")

linux_memory=("Active","Active(anon)","Active(file)","AnonHugePages",
              "AnonPages","Bounce","Buffers","Cached","CmaFree","CmaTotal",
              "CommitLimit","Committed_AS","DirectMap1G","DirectMap2M",
              "DirectMap4k","Dirty","FileHugePages","FilePmdMapped",
              "HardwareCorrupted","HugePages_Free","HugePages_Rsvd",
              "HugePages_Surp","HugePages_Total","Hugepagesize","Hugetlb",
              "Inactive","Inactive(anon)","Inactive(file)","KReclaimable",
              "KernelStack","Mapped","MemAvailable","MemFree","MemTotal",
              "Mlocked","NFS_Unstable","PageTables","Percpu","SReclaimable",
              "SUnreclaim","Shmem","ShmemHugePages","ShmemPmdMapped","Slab",
              "SwapCached","SwapFree","SwapTotal","Unevictable",
              "VmallocChunk","VmallocTotal","VmallocUsed","Writeback",
              "WritebackTmp", "Zswap","Zswapped")

linux_vmstat=("b","bi","bo","buff","cache","cs","free","id","in","r",
              "si","so","st","swpd","sy","us","wa")

linux_iostat=("_%drqm","_%rrqm","_%util","_%wrqm",
              "_aqu-sz","_d/s","_dMB/s",
              "_d_await","_dareq-sz","_drqm/s",
              "_r/s","_rMB/s","_r_await",
              "_rareq-sz","_rrqm/s","_w/s",
              "_wMB/s","_w_await","_wareq-sz",
              "_wrqm/s")

pg_stats=("pg_clients_active","pg_clients_idle","pg_db_size",
          "pg_max_query_runtime_sec")

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

def images_dir(options):
    server=options['server']
    test=str(options['test'])
    # TODO Deal with output to server/test directory given some are missing
    base=os.path.join("results","images")
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
            'Dirty','Active','Cached'
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

    logo_file="reports/Color Horizontal.jpg"
    logo=image.imread(logo_file)
    logo_im = OffsetImage(logo, zoom=.03)

    # This function combines multiple metrics onto a shared Y axis
    # TODO Break out the single metric use case to another function
    if (True):
        view_set=['min_latency','max_latency','avg_latency']
        ylabel="Latency (ms)"
        view_label='Latency '+str(test)
    else:
        view_set=['rate']
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

        if k in view_set:
            rendered=rendered+1

            if k in linux_memory:
                # Linux mem figures are in KB, rescale
                v['avg'] /= (1024 )
                v['max'] /= (1024)
                print("Reprocessed")
                print(v)
                ylabel="Memory MB"

            ax=v['avg'].plot(rot=90,title=view_label,figsize=(8,6))
            #,color=colors[rendered])

            # TODO This just shows avg/avg/avg on legend, should be min/avg/max
            #ax.legend()

            ax.set_ylabel(ylabel)
            ax.grid(True,which='both')

            fn=gen_file_name(base,k,server,test)
            # Only save on last metric in the view list
            if rendered==(len(view_set)):
                # TODO Bottom part of graph is strangely cut off?  Rotation issue?
                plt.savefig(fn,dpi=600)  # 80 for =640x480 figures
                print("saved to '%s.png'" % fn)

                ab = AnnotationBbox(logo_im, (1, 0), frameon=False, xycoords='axes fraction',
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
