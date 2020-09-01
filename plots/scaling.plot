set terminal pngcairo size 640,480 enhanced font ',10'
set output "scaling.png"
set title "pgbench transactions/sec"
set grid xtics ytics
set xlabel "Scaling factor"
set ylabel "TPS"
set y2label "Database Size (MB)"
set ytics nomirror
set y2tics
# y2tics sets the increment between ticks, not their number
set y2tics autofreq

plot \
  "scaling.txt" using 1:3 axis x1y1 title 'TPS' with linespoints,\
  "scaling.txt" using 1:2 axis x1y2 title 'Database Size' with linespoints
