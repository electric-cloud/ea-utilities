#!/usr/bin/perl
#
# Converts /var/log/ecagent.log timestamps from epoch to human readable
# datestamp (e.g. 2016-05-18T15:04:22) and outputs to STDOUT.
#
# Usage is:
#
#       ./agentLogConverter.pl ecagent.log
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


use POSIX qw(strftime);
use strict;


# Get log file from command line
my $filename = $ARGV[0];

# Open log for reading
open(my $fh, '<:encoding(UTF-8)', $filename)
  or die "Could not open file '$filename' $!";
 
# Loop through each line, replacing epoch timestamp with human readable datestamp
while (my $line = <$fh>) {
   $line =~ s/]/] /g; # make sure there's at least one space after first word closing bracket so split works properly
   $line =~ s/ +/ /g; # get rid of extra spaces so split works consistently
   my @words = split / /, $line, 4;
   my $timestamp=strftime("%Y-%m-%dT%H:%M:%S",localtime($words[2]));
   printf("%s   %s             %s %s", $words[0], $words[1], $timestamp, $words[3]);
}
