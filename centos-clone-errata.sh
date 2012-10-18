#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk

# Obtains the current date and year.
DATE=`/bin/date +'%Y-%B'`

# Fetches the errata data from centos.org.
mkdir /tmp/centos-errata >/dev/null 2>&1
cd /tmp/centos-errata
rm -f /tmp/centos-errata/* >/dev/null 2>&1
# wget needs a proxy? Then set these
export http_proxy=
export https_proxy=
wget --no-cache -q -O- http://lists.centos.org/pipermail/centos/$DATE/date.html| grep "CentOS-announce Digest" |tail -n 5 |cut -d"\"" -f2|xargs -n1 -I{} wget -q http://lists.centos.org/pipermail/centos/$DATE/{}

# get usernames and passwords
. ./ya-errata-import.cfg
/sbin/ya-errata-import.pl --erratadir=/tmp/centos-errata --server spacewalk --channel centos-x86_64-server-6 --os-version 6 --publish --get-from-rhn --rhn-proxy=xxx --quiet
/sbin/ya-errata-import.pl --erratadir=/tmp/centos-errata --server spacewalk --channel centos-x86_64-server-5 --os-version 5 --publish --get-from-rhn --rhn-proxy=xxx --quiet

rm -f /tmp/centos-errata/*
