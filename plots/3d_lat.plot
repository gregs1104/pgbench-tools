set term png size 640,480
set terminal png small
set output "3d_lat.png"
set title "pgbench transactions/sec"
set ylabel "Scaling factor"
set yrange [*:*] reverse
set xlabel "Rates"
set zlabel "latency"
set dgrid3d 30,30
set hidden3d
splot "3d_lat.txt" u 1:2:3 with lines
