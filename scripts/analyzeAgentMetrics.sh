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
# Copyright (c) 2016 Ken McKnight
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
Usage: $progname [-ahou] [-f file] metricsSummary

Options:
   -a       All analysis options (same as -bou)
   -b       Bandwidth performance analysis (with -f, compare values against second file)
   -d       Side by side diff (must also specify -f)
   -f file  Specify second file for two agent metrics summary file analysis
   -h       help
   -o       Overall time usage performance analysis (with -f, compare values against second file)
   -u       Usage record performance analysis (with -f, compare values against second file)

EOF
   exit 0
}

# Get metrics category
# args:
# $1 - category
# $2 - file
function getMetricsCategory () {
   category=$1
   file=$2

   # Truncate result to produce integer for comparison in displayPerfRanking
   result=`grep "$category" $file | cut -d'(' -f2 | cut -d'.' -f1`

   # Mark incomplete metrics file with special result value of "failed" instead of a number
   if [ "x$result" == "x" ]; then
      result="failed"
   fi

   echo $result
}

# Calculate percentage change for two metrics file comparison
# args:
# $1 - categoryTime1
# $2 - categoryTime2
function calcPercentChange () {
   categoryTime1=$1
   categoryTime2=$2

   if [ $categoryTime1 -gt $categoryTime2 ]; then
      time2=$categoryTime1
      time1=$categoryTime2
   else
      time1=$categoryTime1
      time2=$categoryTime2
   fi

   if [ $time2 -gt 0 ]; then
      pc=$(( ((((time2 - time1) * 1000) / time2) + (time2 > time1 ? 5 : -5)) / 10 ))
   else
      # Handle corner case of both times are zero
      pc=0
   fi

   echo $pc
}

# Display performance ranking for specified category
# args:
# $1 - category name
# $2 - category value
# $3 - category units
# $4 - less than label
# $5 - less than value
# $6 - greater than label
# $7 - greater than value
# $8 - actual value(s)
function displayPerfRanking () {
   categoryName=$1
   categoryValue=$2
   categoryUnits=$3
   lessThanLabel=$4
   lessThanValue=$5
   greaterThanLabel=$6
   greaterThanValue=$7
   actualValue=$8

   # Trap for incomplete metrics file
   if [ $categoryValue == "failed" ]; then
      noSpacesName=`echo $categoryName | sed -e "s/ //g"`
      echo "Error: Category [$noSpacesName] missing from $metricsFile; aborting analysis"
      exit 1
   fi

   if [ $categoryValue -gt $greaterThanValue ]; then
      label="$greaterThanLabel"
   elif [ $categoryValue -lt $lessThanValue ]; then
      label="$lessThanLabel"
   else
      label="Acceptable"
   fi

   echo "$categoryName : $label (${categoryValue}$categoryUnits$actualValue)"
}

# Get percent usage for overall time categories and display analysis
function analyzeOverallTimeUsage () {
   # Extract percentages from metrics file
   commandPercent=`getMetricsCategory "Command:" $metricsFile`
   emakeRequestPercent=`getMetricsCategory "Emake request:" $metricsFile`
   returnPercent=`getMetricsCategory "Return:" $metricsFile`
   idlePercent=`getMetricsCategory "Idle:" $metricsFile`
   endPercent=`getMetricsCategory "End:" $metricsFile`

   # Calculate percentage change if two metrics files specified
   if [ $F_OPT -eq 1 ]; then
      commandPercent2=`getMetricsCategory "Command:" $metricsFile2`
      emakeRequestPercent2=`getMetricsCategory "Emake request:" $metricsFile2`
      returnPercent2=`getMetricsCategory "Return:" $metricsFile2`
      idlePercent2=`getMetricsCategory "Idle:" $metricsFile2`
      endPercent2=`getMetricsCategory "End:" $metricsFile2`

      commandPercentPC=`calcPercentChange $commandPercent $commandPercent2`
      emakeRequestPercentPC=`calcPercentChange $emakeRequestPercent $emakeRequestPercent2`
      returnPercentPC=`calcPercentChange $returnPercent $returnPercent2`
      idlePercentPC=`calcPercentChange $idlePercent $idlePercent2`
      endPercentPC=`calcPercentChange $endPercent $endPercent2`
   fi

   # Display performance rankings
   if [ $F_OPT -eq 0 ]; then
      echo "Overall Time Usage Performance"
      echo "=============================="
      displayPerfRanking "Command      " $commandPercent "%" Warning 50 Good 60
      displayPerfRanking "Emake Request" $emakeRequestPercent "%" Good 10 Warning 15
      displayPerfRanking "Return       " $returnPercent "%" Good 10 Warning 20
      displayPerfRanking "Idle         " $idlePercent "%" Good 10 Warning 20
      displayPerfRanking "End          " $endPercent "%" Good 10 Warning 20
      echo
   else
      echo "Overall Time Usage Performance Percentage Change"
      echo "================================================"
      displayPerfRanking "Command      " $commandPercentPC "%" Good 10 Warning 25
      displayPerfRanking "Emake Request" $emakeRequestPercentPC "%" Good 10 Warning 25
      displayPerfRanking "Return       " $returnPercentPC "%" Good 10 Warning 25
      displayPerfRanking "Idle         " $idlePercentPC "%" Good 10 Warning 25
      displayPerfRanking "End          " $endPercentPC "%" Good 10 Warning 25
      echo
   fi
}

# Get usage record categories and display analysis
function analyzeUsageRecords () {
   # Extract percentages from metrics file
   failedLookup=`getMetricsCategory "Failed lookup  " $metricsFile`
   read=`getMetricsCategory "Read  " $metricsFile`
   lookup=`getMetricsCategory "Lookup  " $metricsFile`
   create=`getMetricsCategory "Create  " $metricsFile`

   # Calculate percentage change if two metrics files specified
   if [ $F_OPT -eq 1 ]; then
      failedLookup2=`getMetricsCategory "Failed lookup  " $metricsFile2`
      read2=`getMetricsCategory "Read  " $metricsFile2`
      lookup2=`getMetricsCategory "Lookup  " $metricsFile2`
      create2=`getMetricsCategory "Create  " $metricsFile2`

      failedLookupPC=`calcPercentChange $failedLookup $failedLookup2`
      readPC=`calcPercentChange $read $read2`
      lookupPC=`calcPercentChange $lookup $lookup2`
      createPC=`calcPercentChange $create $create2`
   fi

   # Display performance rankings
   if [ $F_OPT -eq 0 ]; then
      echo "Usage Records Performance"
      echo "========================="
      displayPerfRanking "Failed Lookup" $failedLookup "%" Good 50 Warning 60
      displayPerfRanking "Read         " $read "%" Good 25 Warning 30
      displayPerfRanking "Lookup       " $lookup "%" Good 10 Warning 15
      displayPerfRanking "Create       " $create "%" Good 2 Warning 10
      echo
   else
      echo "Usage Records Performance Percentage Change"
      echo "==========================================="
      displayPerfRanking "Failed Lookup" $failedLookupPC "%" Good 10 Warning 25 " | ${failedLookup2}% - ${failedLookup}%"
      displayPerfRanking "Read         " $readPC "%" Good 10 Warning 25 " | ${read2}% - ${read}%"
      displayPerfRanking "Lookup       " $lookupPC "%" Good 10 Warning 25 " | ${lookup2}% - ${lookup}%"
      displayPerfRanking "Create       " $createPC "%" Good 10 Warning 25 " | ${create2}% - ${create}%"
      echo
   fi
}

# Get bandwidth value (in MB/s)
# args:
# $1 - category
# $2 - file
# $3 - total (optional)
function getBandwidthValue () {
   category=$1
   file=$2
   total=$3

   # Truncate result to produce integer for comparison in displayPerfRanking
   if [ -z $total ]; then
      result=`grep "$category" $file | cut -d',' -f3 | sed -e 's/^ *//' | cut -d" " -f1 | cut -d'.' -f1`
   else
      # Skip down to get total
      result=`grep -A 3 "$category" $file | grep "Total:" | cut -d',' -f3 | sed -e 's/^ *//' | cut -d" " -f1 | cut -d'.' -f1`
   fi

   # Mark incomplete metrics file with special result value of "failed" instead of a number
   if [ "x$result" == "x" ]; then
      result="failed"
   fi

   echo $result
}

# Get bandwith performance
function analyzeBandwidth() {
   # Extract bandwidth values from metrics files
   netFromEmake=`getBandwidthValue "Network from emake:" $metricsFile`
   netToEmake=`getBandwidthValue "Network to emake:" $metricsFile`
   netFromAgents=`getBandwidthValue "Network from agents:" $metricsFile`
   netToAgents=`getBandwidthValue "Network to agents:" $metricsFile`
   efsDiskReads=`getBandwidthValue "EFS disk reads" $metricsFile 1`
   efsDiskWrites=`getBandwidthValue "EFS disk writes" $metricsFile 1`

   # Calculate percentage change if two metrics files specified
   if [ $F_OPT -eq 1 ]; then
      netFromEmake2=`getBandwidthValue "Network from emake:" $metricsFile2`
      netToEmake2=`getBandwidthValue "Network to emake:" $metricsFile2`
      netFromAgents2=`getBandwidthValue "Network from agents:" $metricsFile2`
      netToAgents2=`getBandwidthValue "Network to agents:" $metricsFile2`
      efsDiskReads2=`getBandwidthValue "EFS disk reads" $metricsFile2 1`
      efsDiskWrites2=`getBandwidthValue "EFS disk writes" $metricsFile2 1`

      netFromEmakePC=`calcPercentChange $netFromEmake $netFromEmake2`
      netToEmakePC=`calcPercentChange $netToEmake $netToEmake2`
      netFromAgentsPC=`calcPercentChange $netFromAgents $netFromAgents2`
      netToAgentsPC=`calcPercentChange $netToAgents $netToAgents2`
      efsDiskReadsPC=`calcPercentChange $efsDiskReads $efsDiskReads2`
      efsDiskWritesPC=`calcPercentChange $efsDiskWrites $efsDiskWrites2`
   fi

   # Display performance rankings
   if [ $F_OPT -eq 0 ]; then
      echo "Bandwidth Performance"
      echo "====================="
      displayPerfRanking "Network from emake " $netFromEmake "MB/s" Warning 5 Good 12
      displayPerfRanking "Network to emake   " $netToEmake "MB/s" Warning 5 Good 12
      displayPerfRanking "Network from agents" $netFromAgents "MB/s" Warning 5 Good 12
      displayPerfRanking "Network to agents  " $netToAgents "MB/s" Warning 5 Good 12
      displayPerfRanking "EFS disk reads     " $efsDiskReads "MB/s" Warning 30 Good 100
      displayPerfRanking "EFS disk writes    " $efsDiskWrites "MB/s" Warning 10 Good 50
      echo
   else
      echo "Bandwidth Performance Percentage Change"
      echo "======================================="
      displayPerfRanking "Network from emake " $netFromEmakePC "%" Good 10 Warning 25 " | ${netFromEmake2}MB/s - ${netFromEmake}MB/s"
      displayPerfRanking "Network to emake   " $netToEmakePC "%" Good 10 Warning 25 " | ${netToEmake2}MB/s - ${netToEmake}MB/s"
      displayPerfRanking "Network from agents" $netFromAgentsPC "%" Good 10 Warning 25 " | ${netFromAgents2}MB/s - ${netFromAgents}MB/s"
      displayPerfRanking "Network to agents  " $netToAgentsPC "%" Good 10 Warning 25 " | ${netToAgents2}MB/s - ${netToAgents}MB/s"
      displayPerfRanking "EFS disk reads     " $efsDiskReadsPC "%" Good 10 Warning 25 " | ${efsDiskReads2}MB/s - ${efsDiskReads}MB/s"
      displayPerfRanking "EFS disk writes    " $efsDiskWritesPC "%" Good 10 Warning 25 " | ${efsDiskWrites2}MB/s - ${efsDiskWrites}MB/s"
      echo
   fi
}

# Show side by side diff
function sideBySideDiff () {
   echo "Side by Side Diff"
   echo "================="
   echo
   diff -y -W 160 $metricsFile $metricsFile2
}


########################################
###                                  ###
###         Main Entry Point         ###
###                                  ###
########################################

# Option defaults
NO_OPT=1 # indicates no options set
B_OPT=0
D_OPT=0
F_OPT=0
O_OPT=0
U_OPT=0

# Parse command line options
while getopts "abdf:hou" opt; do
   case $opt in

   a) B_OPT=1
      O_OPT=1
      U_OPT=1
      NO_OPT=0
      ;;
   b) B_OPT=1
      NO_OPT=0
      ;;
   d) D_OPT=1
      NO_OPT=0
      ;;
   f) metricsFile2="$OPTARG"
      F_OPT=1
      ;;
   h) usage
      exit 0
      ;;
   o) O_OPT=1
      NO_OPT=0
      ;;
   u) U_OPT=1
      NO_OPT=0
      ;;
  \?) echo "Invalid option: -$OPTARG"
      exit 1
      ;;
   esac
done

# Default to overall time usage performance
if [ $NO_OPT -eq 1 ]; then
   O_OPT=1
fi

# What's left is the metrics file
shift $(($OPTIND - 1))

# Get metrics summary file
metricsFile=$1

# Make sure user has specified a metrics summary file
if [ "x$metricsFile" == "x" ] ; then
    echo "Error: Must specify an agent metrics summary file using agentMetrics.sh" 
    exit 1
fi

# Overall time usage performance
if [ $O_OPT -eq 1 ]; then
   analyzeOverallTimeUsage
fi

# Usage records performance
if [ $U_OPT -eq 1 ]; then
   analyzeUsageRecords
fi

# Bandwith performance
if [ $B_OPT -eq 1 ]; then
   analyzeBandwidth
fi

# Display side by side diff of specified metrics files
if [ $D_OPT -eq 1 ]; then
   if [ $F_OPT -eq 1 ]; then
      sideBySideDiff 
   else
      echo "Error: Must specify -f option when using -d" 
      exit 1
   fi
fi
