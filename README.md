# eawrapper

eawrapper provides a wrapper script to ElectricAccelerator emake with common flags 
and methods to manage history/annotation files.

It contains the following files:
* eawrapper.sh - wrapper script
* verify.mk - simple makefile to verify ElectricAccelerator environment is working properly
  * Example: `./eawrapper.sh -- -f verify.mk`
* jobcache.mk - simple makefile to verify Jobcache is working properly
  * Example: `./eawrapper.sh -- -f jobcache.mk`

# Contact Authors
_**Wrapper script**_
* Ken McKnight ([kmcknight@electric-cloud.com](mailto:kmcknight@electric-cloud.com))

_**Jobcache Verification**_
* Alan Post ([apost@electric-cloud.com](mailto:apost@electric-cloud.com"))
</dl>

# Disclaimer
 
This module is free for use. Modify it however you see fit to better your 
experience using ElectricAccelerator. Share your enhancements and fixes.

This module is not officially supported by Electric Cloud. It has undergone no 
formal testing and you may run into issues that have not been uncovered in the 
limited manual testing done so far.

Electric Cloud should not be held liable for any repercussions of using this 
software.
