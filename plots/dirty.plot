set terminal png medium size 640,480
set output "dirty.png"
set title "Dirty Memory"
set grid xtics ytics
set xlabel "Time during test"
set ylabel "Dirty Memory kB"
set xdata time
set timefmt "%s"
plot "dirtydata.txt" using 1:2 with lines

