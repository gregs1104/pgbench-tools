set term png size 640,480
set terminal png medium
set output "rates-clients-latency.png"
set title "pgbench latency for each clients"
set grid xtics ytics
set xlabel "Rates"
set ylabel "Latency"
set ytics nomirror

plot \
  "rates-clients-latency.txt" using 1:9 axis x1y1 title 'Latency 1 client' with linespoints,\
  "rates-clients-latency.txt" using 1:10 axis x1y1 title 'Latency 2 clients' with linespoints,\
  "rates-clients-latency.txt" using 1:11 axis x1y1 title 'Latency 4 clients' with linespoints,\
  "rates-clients-latency.txt" using 1:12 axis x1y1 title 'Latency 8 clients' with linespoints,\
  "rates-clients-latency.txt" using 1:13 axis x1y1 title 'Latency 16 clients' with linespoints,\
  "rates-clients-latency.txt" using 1:14 axis x1y1 title 'Latency 32 clients' with linespoints
