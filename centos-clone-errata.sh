#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the 
# line that says ". ./ya-errata-import.cfg"

# Obtains the current date and year in the format "2012-December"
DATE=`/bin/date +'%Y-%B'`

# Set your spacewalk server
SPACEWALK=127.0.0.1

# create and/or cleanup the errata dir
ERRATADIR=/tmp/centos-errata
(
mkdir $ERRATADIR >/dev/null 2>&1
cd $ERRATADIR
rm -f $ERRATADIR/* >/dev/null 2>&1

# wget needs a proxy? Then set these
export http_proxy=
export https_proxy=

# Use wget to fetch the errata data from centos.org
# Change the tail command to change the number of errata to process (normally max 1 digest per day, so at least 5 days are considered using "-n 5")
wget --no-cache -q -O- http://lists.centos.org/pipermail/centos/$DATE/date.html| grep "CentOS-announce Digest" |tail -n 5 |cut -d"\"" -f2|xargs -n1 -I{} wget -q http://lists.centos.org/pipermail/centos/$DATE/{}
)

# get usernames and passwords
# don't use this if you're using the commandline options for usernames and passwords
. ./ya-errata-import.cfg

# now do the import based on the wget results
# change the channel parameter to your liking
/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --quiet
/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --quiet

# OR do the import and get extra errata info from redhat if possible
# change the channel parameter to your liking
#   and add the option "--redhat-channel <RHN channel name>" if the channel name if not the same as in your spacewalk server
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --get-from-rhn --rhn-proxy=xxx --quiet
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --get-from-rhn --rhn-proxy=xxx --quiet

rm -f $ERRATADIR/*
