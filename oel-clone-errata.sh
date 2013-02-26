#!/bin/bash
# Processes OEL Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the
# line that says ". ./ya-errata-import.cfg"

# set fixed locale
export LC_ALL=C
export LANG=C

# Set your spacewalk server
SPACEWALK=127.0.0.1

# create and/or cleanup the errata dir
ERRATADIR=/tmp/epel-errata
mkdir $ERRATADIR >/dev/null 2>&1
rm -f $ERRATADIR/* >/dev/null 2>&1

(
   cd $ERRATADIR
   # wget needs a proxy? Then set these
   export http_proxy=
   export https_proxy=

   # now download the errata, in this example we do it for OEL-5-x86_64
   wget -q --no-cache http://public-yum.oracle.com/repo/OracleLinux/OL5/latest/x86_64/repodata/updateinfo.xml.gz
   gunzip updateinfo.xml.gz
)

# Set usernames and passwords. You have some options here:
# 1) Either define the environment variables here:
# export SPACEWALK_USER=my_username
# export SPACEWALK_PASS=my_passwd
# export RHN_USER=my_rhn_username
# export RHN_PASS=my_rhn_password
# 2) Set them on the commandline (but I don't recommend it)
# 3) Set them in a separate cfg file and source it (like done below)
. ./ya-errata-import.cfg

# upload the errata to spacewalk
/sbin/ya-errata-import.pl --oel_errata $ERRATADIR/updateinfo.xml --server $SPACEWALK --channel oel-x86_64-server-6 --os-version 6 --publish --redhat --startfromprevious twoweeks --quiet

rm -f $ERRATADIR/*
