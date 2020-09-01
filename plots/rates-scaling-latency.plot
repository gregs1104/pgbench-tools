set terminal pngcairo size 640,480 enhanced font ',10'
set output "rates-scaling-latency.png"
set title "pgbench latency for each scale"
set grid xtics ytics
set xlabel "Rates"
set ylabel "Latency"
set ytics nomirror

plot \
  "rates-scaling-latency.txt" using 1:7 axis x1y1 title 'Latency scale 1' with linespoints,\
  "rates-scaling-latency.txt" using 1:8 axis x1y1 title 'Latency scale 10' with linespoints,\
  "rates-scaling-latency.txt" using 1:9 axis x1y1 title 'Latency scale 100' with linespoints,\
  "rates-scaling-latency.txt" using 1:10 axis x1y1 title 'Latency scale 1000' with linespoints
