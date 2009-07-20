set term png
set size 0.75,0.75
set output "3d.png"
set title "pgbench transactions/sec"
set ylabel "Scaling factor"
set yrange [*:*] reverse
set xlabel "Clients"
set zlabel "TPS"
set dgrid3d 30,30
set hidden3d
splot "3d.txt" u 2:1:3 with lines

