#!/bin/sh
# the next line restarts using tclsh and supports both linux and cygwin \
if [ `uname -o` = "Cygwin" ]; then myPath=`cygpath -w "$0"`; else myPath="$0"; fi && exec tclsh "$myPath" "$@"

# annodiff -
#
# 'annodiff' takes as input two emake annotation files from 
# a build and produces a diff of job durations based on anno1's
# serial order compared to anno2
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
    {comparison.arg "all" "Delta comparison: one of all|better|worse; default:"}
    {delta.arg 60         "Delta to be displayed. 'value' in seconds; default:"}
    {format.arg "short"   "Format output: one of short|long; default:"}
}

# Diff two anno files based on serial order of the first (e.g. anno1)
proc diffAnnos {} {
    global g opt

    # set target mismatch flag
    set mismatch 0

    # set j2 original location before mismatch flag
    set j2Save ""
    set j2Restore 0

    # set initial iterators for anno1/anno2
    set j1 [$g(anno1) jobs begin]
    set e1 [$g(anno1) jobs end]
    set j2 [$g(anno2) jobs begin]
    set e2 [$g(anno2) jobs end]

    # loop through all jobs
    while {$j1 != $e1} {
        # move on to next job in anno1 if no match found in anno2
        if {$j2 == $e2 || $j2Restore == 1} {
            # restore j2 to original location of mismatch
            set j2 $j2Save

            # force move on to next target in anno1 if no match in anno2
            # otherwise there was a match later on in j2 and j1 was
            # automatically incremented at the end of the loop
            if {$j2Restore == 0} {
                set j1 [$g(anno1) job next $j1]
            }

            # reset j2 restore flag
            set j2Restore 0
        }

        # get target for anno1/anno2
        set target1 [$g(anno1) job name $j1]
        set target2 [$g(anno2) job name $j2]

        # see if serial order is the same
        if {[string equal $target1 $target2]} {
            # yes - get additional info
            # anno1 info
            set start1 [$g(anno1) job start $j1]
            set finish1 [$g(anno1) job finish $j1]
            set duration1 [$g(anno1) job length $j1]

            # anno2 info
            set start2 [$g(anno2) job start $j2]
            set finish2 [$g(anno2) job finish $j2]
            set duration2 [$g(anno2) job length $j2]

            # if match found after at least one mismatch then restore j2
            # to original location of mismatch on next iteration
            if {$mismatch == 1} {
                # restore j2 to original location of mismatch
                set j2Restore 1
             }

            # rest mismatch flag
            set mismatch 0
        } else {
            # targets don't match; keep searching anno2 for a match
            if {$mismatch == 0} {
                puts ">>>>Targets don't match: <$target1 >$target2"
                set mismatch 1
                set j2Save $j2
            }
            set j2 [$g(anno2) job next $j2]
            continue
        }

        # delta
        set delta [expr {$duration2 - $duration1}]
        set absDelta [expr abs($delta)]

        # display short or long format delta output
        if {([string equal $opt(comparison) "all"]) ||
            ([string equal $opt(comparison) "better"] && $delta < 0 && $absDelta > $opt(delta)) ||
            ([string equal $opt(comparison) "worse"] && $delta > 0 && $absDelta > $opt(delta)) } {
            if {[string equal $opt(format) "short"]} {
                puts "$target1 <$j1 >$j2 <>$delta"
            } else {
                puts "$target1 <>$delta"
                puts "<$j1 Start:$start1 Finish:$finish1 Duration:$duration1"
                puts ">$j2 Start:$start2 Finish:$finish2 Duration:$duration2\n"
            }
        }

        # next job for anno1/anno2
        set j1 [$g(anno1) job next $j1]
        set j2 [$g(anno2) job next $j2]
    }
}

# ----------------------------------------------------------------------------
# main
# ----------------------------------------------------------------------------
proc main {} {
    global argv opt g

    # Build up the usage string
    set usage "\[-help\] \[-comparison value\] \[-delta value\] \[-format value\] anno1 anno2\n\n"
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
    if {[llength $argv] < 2} {
        puts stderr "Error: Missing required anno1/anno2 files"
        exit 1
    }

    # Required arguments are the annotation files
    set anno1 [lindex $argv 0]
    set anno2 [lindex $argv 1]

    # Open anno1 and parse it
    if {[catch {open $anno1 r} fd]} {
        puts stderr "Error: $fd"
        exit 1
    }
    set g(anno1) [anno create]
    fconfigure $fd -translation binary -encoding binary
    $g(anno1) load $fd

    # Open anno2 and parse it
    if {[catch {open $anno2 r} fd]} {
        puts stderr "Error: $fd"
        exit 1
    }
    set g(anno2) [anno create]
    fconfigure $fd -translation binary -encoding binary
    $g(anno2) load $fd

    # Print duration differences between anno1 and anno2, based on serial
    # order of anno1
    puts "<$anno1"
    puts ">$anno2\n"

    diffAnnos
}

# execute the main routine
main
