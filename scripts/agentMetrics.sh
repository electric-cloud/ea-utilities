#!/bin/sh
#
# This script is intended to automate the generation of agent side metrics
# Usage is:
#
#       ./agentMetrics.sh buildId
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

# debug
#set -xv

# Template substitutions (replace defaults with appropriate values for your environment)
cmHost=""
installDir="/opt/ecloud/i686_Linux"
cmtoolExe="$installDir/bin/cmtool"
tclSh="$installDir/bin/tclsh"
agentSummary="$installDir/unsupported/agentsummary"

progname=$0

function usage () {
   cat <<EOF
Usage: $progname [-h] buildId

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
buildId=$*

# Make sure user has specified a buildId
if [ "x$buildId" = "x" ] ; then
    echo "Must specify a buildId"
    exit 1
fi

# Make sure cmHost has been configured.
if [ "x$cmHost" = "x" ] ; then
    echo "'cmHost' must be set to the hostname or IP address of your "
    echo "ElectricAccelerator Cluster Manager."
    exit 1
fi


# Minimum required options
cm="--server=$cmHost"

# Make sure user is logged into CM
cmLoginLog="/tmp/cmLogin.$$.tmp"
echo "Logging into CM..."
$cmtoolExe $cm login admin changeme > $cmLoginLog 2>&1
if [ $? -ne 0 ]; then
   cat $cmLoginLog
   rm $cmLoginLog
   exit 1
fi

# Generate metrics
echo "Retrieving raw agent metrics data..."
$cmtoolExe $cm runAgentCmd "session performance $buildId" > build${buildId}.agentraw
echo "Creating summary agent metrics file build${buildId}.agentsum"
$tclSh $agentSummary build${buildId}.agentraw > build${buildId}.agentsum
