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
title_string=sprintf("Internet Speed Analysis\nin %s\n%s to %s", csv_file, edate, ldate)

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
plot csv_file using 2:3:($3 < 50 ? 0 : 1) \
     with linespoints palette pt 5 lw 3 title "Mbps"
pause -1 "Press ENTER to exit the plot? "