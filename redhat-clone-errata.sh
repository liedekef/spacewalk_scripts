#!/bin/bash
# Processes RedHat Errata and imports it into Spacewalk

# Obtains the current date and year.
DATE=`/bin/date +'%Y-%B'`

# Set your spacewalk server
SPACEWALK=127.0.0.1

# get usernames and passwords
. ./ya-errata-import.cfg

# now do the import
# change the channel parameter to your liking
#   and add the option "--redhat-channel <RHN channel name>" if the channel name if not the same as in your spacewalk server
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-i386-server-5 --os-version 5 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-i386-server-6 --os-version 6 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-x86_64-server-5 --os-version 5 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server $SPACEWALK --channel rhel-x86_64-server-6 --os-version 6 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
