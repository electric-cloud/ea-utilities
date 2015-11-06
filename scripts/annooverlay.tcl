#!/bin/sh
# restart -*-Tcl-*- \
exec tclsh "$0" "$@"

# 'annooverlay' takes as input up to four (4) emake annotation files from 
# builds that were run in parallel and produces a merged result file with 
# a single color (category overload) for each build that can be loaded 
# into ElectricInsight to inspect shared cluster utilization.
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


# Load annolib based on OS
#load annolib.so annolib
load annolib annolib

# Required packages
package require annolib
package require cmdline

# Command line options
set parameters {
    {annofile.arg "overlay.anno" "Overlay annotation output file; default:"}
}

# Overlay anno xml header/footer
set overlay(header) "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE build SYSTEM \"build.dtd\">
<build id=\"1\">
<make level=\"0\">"
set overlay(footer) "</make>
</build>"

# Set color palette based on job type overload
set color(0) "parse"
set color(1) "statcache"
set color(2) "end"
set color(3) "remake"


# Overlay multiple anno files, setting 'type' attribute to a specific category
# so that an antire build shows up in one color within ElectricInsight 
proc overlayAnnos {anno counter} {
    global fd color

    # loop through all jobs
    set j [$anno jobs begin]
    set e [$anno jobs end]
    for {} {$j != $e} {set j [$anno job next $j]} {
        # get target for anno1/anno2
        set target1 [$anno job name $j]

        # anno1 info
        set invoked [$anno job start $j]
        set completed [$anno job finish $j]
        set node [$anno job agent $j]

        puts $fd "<job id=\"${j}$counter\" type=\"$color($counter)\">"
        puts $fd "<timing invoked=\"$invoked\" completed=\"$completed\" node=\"$node\"/>"
        puts $fd "</job>"
    }
}

# Load annotation file
proc loadAnno {anno counter} {
    global g

    # Open anno and parse it
    if {[catch {open $anno r} fd]} {
        puts stderr "Error: $fd"
        exit 1
    }
    set g(anno$counter) [anno create]
    fconfigure $fd -translation binary -encoding binary
    $g(anno$counter) load $fd
}



# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------
proc main {} {
    global argv opt g overlay fd color

    # Build up the usage string
    set usage "\[-help\] \[-annofile value\] anno1 \[anno2-4\]\n\n"
    append usage "options:"

    # Parse command line options
    if {[catch {array set opt [cmdline::getoptions ::argv $::parameters $usage]}]} {
        if {$argv != ""} {
            puts stderr "Error: $argv is not a valid option\n"
        }
        puts [cmdline::usage $::parameters $usage]
        exit
    }
    #parray opt

    # Whine if we don't have enough arguments
    if {[llength $argv] < 1 || [llength $argv] > 4} {
        puts stderr "Error: can only specify between one and four anno files"
        exit 1
    }

    # Load anno files
    set filecount [llength $argv]
    for {set i 0} {$i < $filecount} {incr i} {
        set anno [lindex $argv $i]
        loadAnno $anno $i
    }

    # Open output file
    if {[catch {open $opt(annofile) w} fd]} {
        puts stderr "Error: $fd"
        exit 1
    }

    # Start with xml header
    puts $fd $overlay(header)

    # Add overlay job info for each anno file
    for {set i 0} {$i < $filecount} {incr i} {
        overlayAnnos $g(anno$i) $i
    }

    # End with xml footer
    puts $fd $overlay(footer)

    # Close file
    close $fd
}

# execute the main routine
main
