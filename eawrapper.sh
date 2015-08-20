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


# Template substitutions (replace defaults with appropriate values for your environment)
cmHost="localhost"
projectName="myProject"
assetDir=".emake"
emakeRoot="."
buildClass="default"
resourceName="default"
emakeOutputDir="emake_outputs"

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

# Invoke emake to do a build (assumes any arguments passed in on the command line are standard
# makefile options (e.g. targets/variables)
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
