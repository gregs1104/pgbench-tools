set term png
set size 0.75,0.75
set output "scaling.png"
set title "pgbench transactions/sec"
set grid xtics ytics
set xlabel "Scaling factor"
set y2label "Database Size (MB)"
set ylabel "TPS"
# y2tics sets the increment between ticks, not their number
set y2tics autofreq
plot \
  "scaling.txt" using 1:3 axis x1y1 title 'TPS' with lines,\
  "scaling.txt" using 1:2 axis x1y2 title 'Database Size (MB)' with lines


