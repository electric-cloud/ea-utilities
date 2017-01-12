#!/bin/sh
#
# This script is intended to provide a starting point for wrapping
# ElectricAccelerator emake with the necessary options to perform a customer
# build.  Usage is:
#
#       ./eawrapper.sh <make options> <targets>
#
# All emake-specific options should be added by this script, so you need only
# specify your normal make options and command-line arguments.
#
# Note: Not all options of emake are specified in this template. For a complete
# list, see the online documentation at http://docs.electric-cloud.com, or use
# 
#       emake --help
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
projectName=""
emakeOutputDir=""
assetDir=".emake"
emakeRoot="."
buildClass="default"
resourceName="default"

progname=$0

function usage () {
   cat <<EOF
Usage: $progname [-a file] [-b file] [-hr] [-- gmake/emake options] [target ...]

Options:
   -a file post-build hook
   -b file pre-build hook
   -h      help
   -r      reset history (aka no-history build - history file backed up)

If specifying a make option then it must be preceded by '--'. For example:
$progname -r -- -f ../makefiles/verify.mk all

EOF
   exit 0
}

# Defaults for command line options
optPreBuildHook=0
optPostBuildHook=0
optResetHistory=0

# Parse command line options
while getopts ":a:b:hr" opt; do
   case $opt in

   a) optPostBuildHook=1
      postBuildHookFile=$OPTARG
      ;;
   b) optPreBuildHook=1
      preBuildHookFile=$OPTARG
      ;;
   h) usage
      exit 0
      ;;
   r) optResetHistory=1
      ;;
  \?) echo "Invalid option: -$OPTARG"
      exit 1
      ;;
   esac
done

# Everything else is make option related
# Note: if specifying a make switch then use '--' first (e.g. ./eawrapper.sh -a -- -f verify.mk all)
shift $(($OPTIND - 1))

# Make sure cmHost has been configured.

if [ "x$cmHost" = "x" ] ; then
    echo "'cmHost' must be set to the hostname or IP address of your "
    echo "ElectricAccelerator Cluster Manager."
    echo "Edit $progname to set this variable" 
    exit 1
fi

# Make sure projectName has been configured.

if [ "x$projectName" = "x" ] ; then
    echo "'projectName' must be set to the name of your project."
    echo "Edit $progname to set this variable" 
    exit 1
fi

# Spare the user some pain by prohibiting spaces in projectName.

if echo "$projectName" | grep -E '[ "]' > /dev/null ; then
    echo "'projectName' must not contain spaces."
    exit 1
fi

# Make sure emakeOutputDir has been configured.

if [ "x$emakeOutputDir" = "x" ] ; then
    echo "'emakeOutputDir' must be set to a writable directory with enough"
    echo "free space for Electric Make annotation, history and debug logs."
    echo "Edit $progname to set this variable" 
    exit 1
fi

# Derived paths
annoDir="$emakeOutputDir/anno"
historyDir="$emakeOutputDir/history"
historyFile="$historyDir/${projectName}.data"
debugDir="$emakeOutputDir/debug"

# Minimum required options
emakeCM="--emake-cm=$cmHost"
emakeRoot="--emake-root=$emakeRoot"
emakeHistoryFile="--emake-historyfile=$historyFile"

# Asset directory (default = .emake in directory where emake started)
#emakeAssetDir="--emake-assetdir=$assetDir"

# Build class / resource
#emakeClass="--emake-class=$buildClass"
#emakeResource="--emake-resource=$resourceName"

# History options
emakeHistoryMode="--emake-history=merge"
#emakeHistoryMode="--emake-history=create"
# for builds with globbing issues - see emake guide for details before using
#emakeReaddirConflicts="--emake-readdir-conflicts=1"

# Annotation options
# Note: see emake guide for complete list of macros available for use with annofile name
#
emakeAnnoFile="--emake-annofile=$annoDir/${projectName}_@ECLOUD_BUILD_ID@.anno"
emakeAnnoDetail="--emake-annodetail=basic,history,waiting"
# kitchen sink - definitely affects performance of build so be careful
#emakeAnnoDetail="--emake-annodetail=basic,history,waiting,file,lookup,env"

# Debug options
# Note: see 'emake --help' for complete list of debug options
#
# job/node debug (a good place to start when debugging)
#emakeDebug="--emake-debug=jn"
# client side metrics
#emakeDebug="--emake-debug=g" # client side metrics
#emakeLogfile="--emake-logfile=$debugDir/${projectName_@ECLOUD_BUILD_ID@.dlog"

# Performance optimizations
# Note: only enable after a basic build is working
#
#emakeParseAvoidance="--emake-parse-avoidance=1"
#emakeJobcache="--emake-jobcache=gcc"
#emakeAutoDepend="--emake-autodepend=1 --emake-suppress-include=*.d"

# House keeping (e.g. make sure directories exist)
mkdir -p "$annoDir"
mkdir -p "$historyDir"
mkdir -p "$debugDir"

# Reset history (make backup of history file)
if [ $optResetHistory = 1 ]; then
   datestamp=`date +%Y%m%d%H%M%S`
   mv "$historyFile" "$historyFile.$datestamp"
fi

# Execute optional pre-build hook
if [ $optPreBuildHook = 1 ]; then
   if [ -x $preBuildHookFile ]; then
      . $preBuildHookFile
   else
      echo "$preBuildHookFile does not exist or is not executable"
      exit 1
   fi
fi

# Invoke emake to do a build; assumes any arguments passed in on the command line are standard
# makefile options (e.g. targets/variables) or additional emake options
emake $emakeCM \
      $emakeRoot \
      $emakeHistoryFile \
      $emakeHistoryMode \
      $emakeReaddirConflicts \
      $emakeAnnoFile \
      $emakeAnnoDetail \
      $emakeDebug \
      $emakeLogfile \
      $emakeClass \
      $emakeResource \
      $emakeAssetDir \
      $emakeParseAvoidance \
      $emakeJobcache \
      $emakeAutoDepend \
      $*

# Execute optional post-build hook
if [ $optPostBuildHook = 1 ]; then
   if [ -x $postBuildHookFile ]; then
      . $postBuildHookFile
   else
      echo "$postBuildHookFile does not exist or is not executable"
      exit 1
   fi
fi
