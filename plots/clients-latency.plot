set term png size 640,480
set terminal png medium
set output "clients-latency.png"
set title "pgbench latency"
set grid xtics ytics
set xlabel "Clients"
set ylabel "Latency"
plot \
  "clients-latency.txt" using 1:2 axis x1y1 title 'Latency' with linespoints
