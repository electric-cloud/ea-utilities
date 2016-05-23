#!/bin/sh
#
# Provide guidance on agent metrics summary based on Eric Melski blogs
# http://electric-cloud.com/blog/2008/10/digging-into-accelerator-agent-metrics-part-1/
# http://electric-cloud.com/blog/2008/11/electricaccelerator-agent-metrics-part-2/
#
# Usage is:
#
#       ./analyzeAgentMetrics.sh metricsSummary
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
Usage: $progname [-h] metricsSummary

Options:
   -h      help

EOF
   exit 0
}

# Get metrics category
# args:
# $1 - category
function getMetricsCategory () {
   category=$1

   # Truncate result to produce integer for comparison in displayPerfRanking
   result=`grep "$category" $metricsFile | cut -d'(' -f2 | cut -d'.' -f1`

   # Mark incomplete metrics file with special result value of "failed" instead of a number
   if [ "x$result" == "x" ]; then
      result="failed"
   fi

   echo $result
}

# Display performance ranking for specified category
# args:
# $1 - category name
# $2 - usage percent
# $3 - less than label
# $4 - less than percent
# $5 - greater than label
# $6 - greater than percent
function displayPerfRanking () {
   categoryName=$1
   usagePercent=$2
   lessThanLabel=$3
   lessThanPercent=$4
   greaterThanLabel=$5
   greaterThanPercent=$6

   # Trap for incomplete metrics file
   if [ $usagePercent == "failed" ]; then
      noSpacesName=`echo $categoryName | sed -e "s/ //g"`
      echo "Error: Category [$noSpacesName] missing from $metricsFile; aborting analysis"
      exit 1
   fi

   if [ $usagePercent -gt $greaterThanPercent ]; then
      label="$greaterThanLabel"
   elif [ $usagePercent -lt $lessThanPercent ]; then
      label="$lessThanLabel"
   else
      label="Acceptable"
   fi

   echo "$categoryName : $label (${usagePercent}%)"
}

# Get percent usage for overall time categories and display analysis
function analyzeOverallTimeUsage () {
   # Extract percentages from metrics file
   commandPercent=`getMetricsCategory "Command:"`
   emakeRequestPercent=`getMetricsCategory "Emake request:"`
   returnPercent=`getMetricsCategory "Return:"`
   idlePercent=`getMetricsCategory "Idle:"`
   endPercent=`getMetricsCategory "End:"`


   # Display performance rankings
   displayPerfRanking "Command      " $commandPercent Warning 50 Good 60
   displayPerfRanking "Emake Request" $emakeRequestPercent Good 10 Warning 15
   displayPerfRanking "Return       " $returnPercent Good 10 Warning 20
   displayPerfRanking "Idle         " $idlePercent Good 10 Warning 20
   displayPerfRanking "End          " $endPercent Good 10 Warning 20
}

# Get usage record categories and display analysis
function analyzeUsageRecords () {
   # Extract percentages from metrics file
   failedLookup=`getMetricsCategory "Failed lookup  "`
   read=`getMetricsCategory "Read  "`
   lookup=`getMetricsCategory "Lookup  "`
   create=`getMetricsCategory "Create  "`

   # Display performance rankings
   displayPerfRanking "Failed Lookup" $failedLookup Good 50 Warning 60
   displayPerfRanking "Read         " $read Good 25 Warning 30
   displayPerfRanking "Lookup       " $lookup Good 10 Warning 15
   displayPerfRanking "Create       " $create Good 2 Warning 10
}

# Show side by side diff
function sideBySideDiff () {
   echo "Side by Side Diff"
   echo "================="
   echo
   diff -y -W 160 $metricsFile $dstMetricsFile
}


########################################
###                                  ###
###         Main Entry Point         ###
###                                  ###
########################################

# Option defaults
D_OPT=0

# Parse command line options
while getopts "d:h" opt; do
   case $opt in

   d) dstMetricsFile="$OPTARG"
      D_OPT=1
      ;;
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

# Get metrics summary file
metricsFile=$*

# Make sure user has specified a metrics summary file
if [ "x$metricsFile" == "x" ] ; then
    echo "Error: Must specify an agent metrics summary file using agentMetrics.sh" 
    exit 1
fi

# If -d option specified, make sure user has specified a destination metrics summary file for diffing
if [ $D_OPT -eq 1 -a "x$dstMetricsFile" == "x" ] ; then
    echo "Error: Must specify a second agent metrics summary file when specifying -d option" 
    exit 1
fi

# Overall time usage performance
echo "Overall Time Usage Performance"
echo "=============================="
analyzeOverallTimeUsage
echo

# Usage records performance
echo "Usage Records Performance"
echo "========================="
analyzeUsageRecords
echo

# Display side by side diff of specified metrics files
if [ $D_OPT -eq 1 ]; then
   sideBySideDiff 
fi
