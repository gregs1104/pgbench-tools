#!/usr/bin/env python

import sys
import datetime
import csv

test=sys.argv[1]
out=csv.writer(sys.stdout,delimiter=',')
for l in sys.stdin:
  l=l.strip()
  (client,trans,latency,filenum,sec,usec)=l.split(" ")
  latency=float(latency) / 1000
  timestamp=float(sec)+float(usec) / 1000000
  d=datetime.datetime.fromtimestamp(timestamp)
  r=[d.isoformat(" "),filenum,latency,test]
  out.writerow(r)

