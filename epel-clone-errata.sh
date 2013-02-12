#!/bin/bash
# Processes EPEL Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the
# line that says ". ./ya-errata-import.cfg"

# Fetches the errata data 
mkdir /tmp/epel-errata >/dev/null 2>&1
cd /tmp/epel-errata
rm -f /tmp/epel-errata/* >/dev/null 2>&1

# Set your spacewalk server
SPACEWALK=127.0.0.1

# get usernames and passwords
# don't use this if you're using the commandline options for usernames and passwords
. ./ya-errata-import.cfg

# if wget needs a proxy, set it here
export http_proxy=
export https_proxy=

# now download the errata, in this example we do it for EPEL-6-x86_64
wget -q --no-cache http://dl.fedoraproject.org/pub/epel/6/x86_64/repodata/updateinfo.xml.gz
gunzip /tmp/epel-errata/updateinfo.xml.gz
# upload the errata to spacewalk, for a channel used by redhat servers:
/sbin/ya-errata-import.pl --epel_errata updateinfo.xml --server $SPACEWALK --channel rhel-x86_64-server-6-epel --os-version 6 --publish --redhat --startfromprevious twoweeks --quiet
# upload the errata to spacewalk, for a channel used by centos servers:
/sbin/ya-errata-import.pl --epel_errata updateinfo.xml --server $SPACEWALK --channel centos-x86_64-server-6-epel --os-version 6 --publish --startfromprevious twoweeks --quiet

rm -f /tmp/epel-errata/*
