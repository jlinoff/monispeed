#!/usr/bin/env gnuplot -c
# Plot connection speed data.
# Usage Examples:
#   $ ./plot-speed.gp                    # defaults to speed.csv, outputs to screen
#   $ ./plot-speed.gp speed.csv           # output to screen
#   $ ./plot-speed.gp speed.csv speed.png  # write output to speed.png

# Grab command line arguments
csv_file = "speed.csv"
png_file = ''
if (strlen(ARG1) > 0 ) csv_file = ARG1;
if (strlen(ARG2) > 0 ) png_file = ARG2;

itype = csv_file[strlen(csv_file)-3:strlen(csv_file)]
otype = ''
if ( strlen(png_file) > 0 ) {
    otype = png_file[strlen(png_file)-3:strlen(png_file)]
}
msg = 'output to screen'
if ( strlen(png_file) > 0 ) {
    msg = 'output to file'
}
print "script name: ", ARG0
print "input file : ", csv_file
print "output     : ", png_file
print "mode       : ", msg
if ( itype ne ".csv" ) {
    print "ERROR: unrecognized input file extension '", itype, "', must be '.csv'"
    exit
}
if ( strlen(otype) > 0 && otype ne '.png' ) {
    print "ERROR: unrecognized output file extension '", itype, "', must be '.png'"
    exit
}

# collect stats from interesting columns
set datafile separator ','
stats csv_file using 3  # speed
speed_mean = STATS_mean
speed_min = STATS_min
speed_max = STATS_max
speed_median = STATS_median
speed_lb = 50  # lower bound
speed_nom = 100 # nominal speed

# initialize
set term qt font "Arial,18"
set datafile separator ','
set xdata time                          # tells gnuplot the x axis is time data
set timefmt "%Y-%m-%dT%H:%M:%S-07:00"   # specify our time string format
set format x "%m-%d\n%H:%M" # otherwise it will show only MM:SS
set yrange[0:]

# set title
edate=system(sprintf("head -2 %s | tail -1 | awk -F, '{print $2}'", csv_file)) # skip header
ldate=system(sprintf("tail -1 %s | awk -F, '{print $2}'", csv_file))
print "earliest   : ", edate
print "latest     : ", ldate
title_string=sprintf("Internet Speed Analysis\nin %s\n%s to %s\nmean: %.2f [%.2f -> %.2f]\nmedian: %2.f", \
                               csv_file, edate, ldate, speed_mean, speed_min, speed_max, speed_median)

set title title_string
set xlabel "date/time"
set ylabel "speed (Mbps)"

# setup term
if ( strlen(png_file) == 0 ) {
    # to screen
    # plot
    set term qt font "Arial,14"
    #set term qt size 1200, 800
    set term qt size 1440, 900
} else {
    set term png
    set term png font "Arial,14"
    set term png size 1440, 900
    set output png_file
}

set palette model RGB defined ( 0 'light-red', 1 'forest-green' )
plot csv_file using 2:3:($3 < 50 ? 0 : 1) with linespoints palette pt 5 lw 3 title "Mbps", \
     '' using 2:(speed_median) with linespoints lc rgb "purple" lt 0 lw 1 title sprintf('median (%.2f)', speed_median), \
     '' using 2:(speed_mean) with linespoints lc rgb "blue" lt 0 lw 1 title sprintf('mean (%.2f)', speed_mean), \
     '' using 2:(speed_lb) with linespoints lc rgb "red" lt 0 lw 1 title sprintf('low bound (%.2f)', speed_lb), \
     '' using 2:(speed_nom) with linespoints lc rgb "dark-green" lt 0 lw 1 title sprintf('nominal (%.2f)', speed_nom)
pause -1 "Press ENTER to exit the plot? "