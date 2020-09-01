set terminal pngcairo size 640,480 enhanced font ',10'
set output "3d.png"
set title "pgbench transactions/sec"
set ylabel "Scaling factor"
set yrange [*:*] reverse
set xlabel "Clients"
set zlabel "TPS"
set dgrid3d 30,30
set hidden3d
splot "3d.txt" u 2:1:3 with lines
