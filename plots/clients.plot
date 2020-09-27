set terminal pngcairo size 640,480 enhanced font ',10'
set output "clients.png"
set title "pgbench transactions/sec"
set grid xtics ytics
set xlabel "Clients"
set ylabel "TPS"
set key right bottom
plot \
  "clients.txt" using 1:2 axis x1y1 title 'TPS' with linespoints
