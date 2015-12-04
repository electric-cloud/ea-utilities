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
    {utilization                 "Display unused cluster utilization"}
}

# Overlay anno xml header/footer
set overlay(header) "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE build SYSTEM \"build.dtd\">
<build id=\"1\">
<make level=\"0\">"
set overlay(footer) "</make>
</build>"

# Set color palette based on job type and status overloads
set color(0) "type=\"parse\""
set color(1) "type=\"statcache\""
set color(2) "type=\"end\""
set color(3) "type=\"remake\""
set color(4) "type=\"rule\""
set color(5) "type=\"rule\" status=\"conflict\""
set color(6) "type=\"rule\" status=\"rerun\""
set color(7) "type=\"rule\" status=\"reverted\""


# Overlay multiple anno files, setting 'type' attribute to a specific category
# so that an entire build shows up in one color within ElectricInsight 
proc overlayAnnos {anno counter} {
    global fd color g

    # Calculate offset
    set offset [expr {$g(startTime$counter) - $g(baseline)}]

    # loop through all jobs
    set j [$anno jobs begin]
    set e [$anno jobs end]
    for {} {$j != $e} {set j [$anno job next $j]} {
        # anno info
        set invoked [$anno job start $j]
        set completed [$anno job finish $j]
        set node [$anno job agent $j]

        # Compensate for build start time compared to baseline
        set compInvoked [expr {$invoked + $offset}]
        set compCompleted [expr {$completed + $offset}]

        # Add colorized job info to overlay anno output file
        puts $fd "<job id=\"${j}$counter\" $color($counter) name=\"$g(annoName$counter)\">"
        puts $fd "<timing invoked=\"$compInvoked\" completed=\"$compCompleted\" node=\"$node\"/>"
        puts $fd "</job>"

        # Update jobDuration and totalDuration counters
        set g(jobDuration) [expr {$g(jobDuration) + ($completed - $invoked)}]
        if { $compCompleted > $g(totalDuration) } {
            set g(totalDuration) $compCompleted
        }

        # Also update agent count if it's larger
        # Note: this isn't 100% accurate because the true agent count is a merger
        #       of all the agents used for every anno file specified; I'm just
        #       grabbing the largest count out of the bunch
        set agentCount [llength [$anno agents]]
        if { $agentCount > $g(totalAgents) } {
            set g(totalAgents) $agentCount
        }
    }
}

# Load annotation file
proc loadAnno {anno counter} {
    global g color

    # Show status
    puts "Loading anno $anno \[mapping:$color($counter)\]"

    # Open anno and parse it
    if {[catch {open $anno r} fd]} {
        puts stderr "Error: $fd"
        exit 1
    }
    set g(anno$counter) [anno create]
    fconfigure $fd -translation binary -encoding binary
    $g(anno$counter) load $fd
}

# Get start time of build
proc getStartTime {anno counter} {
    global g

    # Look for 'start' attribute of <build> element
    set pattern {.*start="(.*)"}

    set fid [open $anno r]
    while {[gets $fid line] != -1} {
        if { [regexp $pattern $line matched startDatestamp] } { break }
    }
    close $fid

    # Now convert datestamp to seconds since epoch
    # Example: Tue Nov 10 14:22:11 2015
    set g(startTime$counter) [clock scan $startDatestamp -format "%a %b %d %H:%M:%S %Y"]

    # If baseline is unset (0) then initialize to current value
    if { $g(baseline) == 0 } {
        set g(baseline) $g(startTime$counter)
    }

    # Update baseline if current start time is smaller
    if { $g(startTime$counter) < $g(baseline) } {
        set g(baseline) $g(startTime$counter)
    }
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
    # Note: max files accepted is constrained by number of mapping colors available
    set maxFiles [array size color]
    if {[llength $argv] < 1 || [llength $argv] > $maxFiles} {
        puts stderr "Error: can only specify between one and $maxFiles anno files"
        exit 1
    }

    # Default baseline value 0=unset
    set g(baseline) 0

    # Set defaults for total duration for all annos used in the overlay
    # as well as duration calculated from adding up all job times
    set g(totalDuration) 0
    set g(jobDuration) 0
    set g(totalAgents) 0

    # Load anno files and also get build start time
    # As a side effect, getStartTime also calculates the time baseline
    set filecount [llength $argv]
    for {set i 0} {$i < $filecount} {incr i} {
        set anno [lindex $argv $i]
        # also save anno file name so 'overlayAnnos' can set target name
        # to anno file name for convenient mouse over in ElectricInsight
        set g(annoName$i) $anno
        loadAnno $anno $i
        getStartTime $anno $i
    }

    # Open output file
    if {[catch {open $opt(annofile) w} fd]} {
        puts stderr "Error: $fd"
        exit 1
    }

    # Start with xml header
    puts $fd $overlay(header)

    # Add overlay job info for each anno file
    puts "Creating overlay anno file $opt(annofile)"
    for {set i 0} {$i < $filecount} {incr i} {
        overlayAnnos $g(anno$i) $i
    }

    # End with xml footer
    puts $fd $overlay(footer)

    # Close file
    close $fd

    # Display unused cluster utilization percentage
    if { $opt(utilization) } {
        set overlayDuration [expr { $g(totalDuration) * $g(totalAgents) }]
        set unusedUtilization [expr { (($overlayDuration - $g(jobDuration)) / $overlayDuration) * 100 }]
        puts "Unused cluster utilization = [expr round($unusedUtilization)]\%"
    }
}

# execute the main routine
main
