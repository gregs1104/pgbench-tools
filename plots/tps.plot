set terminal png medium size 640,480
set output "tps.png"
set title "TPS"
set grid xtics ytics
set xlabel "Time during test"
set ylabel "TPS"
set xdata time
set timefmt "%s"
plot "tpsdata.txt" using 1:2 with lines

