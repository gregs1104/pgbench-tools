set terminal pngcairo size 640,480 enhanced font ',10'
set output "dirty.png"
set title "Dirty Memory"
set grid xtics ytics
set xlabel "Time during test"
set ylabel "Dirty Memory kB"
set xdata time
set timefmt "%s"
plot "dirtydata.txt" using 1:2 with lines

