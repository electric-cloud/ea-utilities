#!/bin/sh
#
# This script is intended to provide a starting point for wrapping ElectricAccelerator emake
# with the necessary options to perform a customer build.
#
# Note: Not all options of emake are specified in this template. For a complete list, see
#       'emake --help' and the online documentation
#
# This module is free for use. Modify it however you see fit to better your experience using 
# ElectricCommander. Share your enhancements and fixes.
#
# This module is not officially supported by Electric Cloud. It has undergone no formal 
# testing and you may run into issues that have not been uncovered in the limited manual 
# testing done so far.
#
# Electric Cloud should not be held liable for any repercussions of using this software.

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
Usage: $progname [-a file] [-b file] [-h] [-- gmake/emake options] [target ...]

Options:
   -a file post-build hook
   -b file pre-build hook
   -h      help

If specifying a make option then it must be preceded by '--'. For example:
$progname -a -- -f verify.mk all

EOF
   exit 0
}

# Defaults for command line options
optPreBuildHook=0
optPostBuildHook=0

# Parse command line options
while getopts ":a:b:h" opt; do
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
    exit 1
fi

# Make sure projectName has been configured.

if [ "x$projectName" = "x" ] ; then
    echo "'projectName' must be set to the name of your project."
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
    exit 1
fi

# Derived paths
annoDir="$emakeOutputDir/anno"
historyDir="$emakeOutputDir/history"
debugDir="$emakeOutputDir/debug"

# Minimum required options
emakeCM="--emake-cm=$cmHost"
emakeRoot="--emake-root=$emakeRoot"
emakeHistoryFile="--emake-historyfile=$historyDir/${projectName}.data"

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

# House keeping (e.g. make sure directories exist)
mkdir -p "$annoDir"
mkdir -p "$historyDir"
mkdir -p "$debugDir"

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
