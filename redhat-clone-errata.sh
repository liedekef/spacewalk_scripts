#!/bin/bash
# Processes RedHat Errata and imports it into Spacewalk

# Obtains the current date and year.
DATE=`/bin/date +'%Y-%B'`

# get usernames and passwords
. ./ya-errata-import.cfg

# now do the import
/sbin/ya-errata-import.pl --server spacewalk --channel rhel-i386-server-5 --os-version 5 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server spacewalk --channel rhel-i386-server-6 --os-version 6 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server spacewalk --channel rhel-x86_64-server-5 --os-version 5 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
/sbin/ya-errata-import.pl --server spacewalk --channel rhel-x86_64-server-6 --os-version 6 --publish --redhat --rhn-proxy=xxx --redhat-startfromprevious twoweeks --quiet
