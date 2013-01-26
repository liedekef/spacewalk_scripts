#!/bin/bash
# Processes RedHat Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the 
# line that says ". ./ya-errata-import.cfg"

# Obtains the current date and year.
DATE=`/bin/date +'%Y-%B'`

# Set your spacewalk server
SPACEWALK=127.0.0.1

# get usernames and passwords
# don't use this if you're using the commandline options for usernames and passwords
. ./ya-errata-import.cfg

# now do the import
# change the channel parameter to your liking
#   and add the option "--redhat-channel <RHN channel name>" if the channel name if not the same as in your spacewalk server
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-i386-server-5 --os-version 5 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-i386-server-6 --os-version 6 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-x86_64-server-5 --os-version 5 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-x86_64-server-6 --os-version 6 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
