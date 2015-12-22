#!/bin/sh
#
# Create png of memory usage from --emake-debug=m via gnuplot
# Usage is:
#
#       ./plot_mem_usage.sh dlog
#
#
# This module is free for use. Modify it however you see fit to better your
# experience using ElectricAccelerator. Share your enhancements and fixes.
#
#
# Copyright (c) 2015 Ken McKnight
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Electric Cloud nor the names of its employees may
#       be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

progname=$0

function usage () {
   cat <<EOF
Usage: $progname [-h] debugLog

Options:
   -h      help

EOF
   exit 0
}

# Parse command line options
while getopts "h" opt; do
   case $opt in

   h) usage
      exit 0
      ;;
  \?) echo "Invalid option: -$OPTARG"
      exit 1
      ;;
   esac
done

# Everything else is make option related
shift $(($OPTIND - 1))

# Get buildId
dlog=$*

# Make sure user has specified a dlog
if [ "x$dlog" = "x" ] ; then
    echo "Must specify a debug log generated with at least --emake-debug=m"
    exit 1
fi

# defines
gnuplotScript="mem_usage.gpscript"
gnuplotDataFile="size.dat"

# process raw --emake-debug=m data from debug log
echo "Processing raw data..."
egrep ^SIZE= $dlog | sed -e 's/SIZE=\([0-9]*\).*/\1/' | nl > $gnuplotDataFile

# create gnuplot script
echo "Creating gnuplot script..."
echo "set terminal png" > $gnuplotScript
echo "set output 'mem_usage.png'" >> $gnuplotScript
echo "set title \"emake Memory Usage\"" >> $gnuplotScript
echo "set xlabel \"Seconds\"" >> $gnuplotScript
echo "set ylabel \"Memory (MB)\"" >> $gnuplotScript
echo "set key right bottom" >> $gnuplotScript
echo "plot '$gnuplotDataFile' using 1:(\$2/1000000) with lines title \"emake\"" >> $gnuplotScript

# generate png with plot of data
echo "Creating png mem_usage.png..."
gnuplot $gnuplotScript 

# cleanup temp files
rm $gnuplotScript
rm size.dat
