set term png size 640,480
set terminal png medium
set output "clients.png"
set title "pgbench transactions/sec"
set grid xtics ytics
set xlabel "Clients"
set ylabel "TPS"
plot \
  "clients.txt" using 1:2 axis x1y1 title 'TPS' with lines
