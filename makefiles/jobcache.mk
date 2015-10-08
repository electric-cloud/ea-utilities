# Verify jobcache is working
#
# Make sure the following is uncommented in eawrapper.sh:
# emakeJobcache="--emake-jobcache=gcc"
#
# Sample output:
#
# Starting build: 219357
# gcc -c -o quine.o quine.c
# gcc -o quine quine.o
# ./quine | cmp - quine.c
# Finished build: 219357 Duration: 0:01 (m:s)   Cluster availability: 100%
#
# You can see the program is compiled and run, comparing the output of the program to the source code. 
# This test ensures a runable executable was actually created on the target system.
#
# Check if jobcache is enabled (if no matches then something is amiss):
# grep jobcache emake.xml
#
# Remove quine.o/quine.exe. Run emake again. This time there should be cache hits (no recompile).

SHELL=/bin/sh

CC=gcc
LD=gcc

.PHONY: test

test: jobcache.mk quine
	./quine | cmp - quine.c

quine: jobcache.mk quine.o
	$(LD) -o quine quine.o

quine.o: jobcache.mk quine.c
	$(CC) -c -o quine.o quine.c

quine.c:
	echo '#include<stdio.h>' > quine.c
	echo '#include<stdlib.h>' >> quine.c
	echo 'main(){char*c="\\\"#include<stdio.h>%c#include<stdlib.h>%cmain(){char*c=%c%c%c%.129s%cn%c;printf(c+2,c[129],c[129],c[1],*c,*c,c,*c,c[1]);exit(0);}\n";printf(c+2,c[129],c[129],c[1],*c,*c,c,*c,c[1]);exit(0);}' >> quine.c
