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
