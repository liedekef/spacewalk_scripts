#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# also: if you're using the commandline options for usernames and passwords, comment out the 
# line that says ". ./ya-errata-import.cfg"

# set fixed locale
export LC_ALL=C
export LANG=C

# Set your spacewalk server
SPACEWALK=127.0.0.1

# The number of digests to download
# Since the digests are normally only downloaded for 1 month, any number bigger than 31 makes no sence
NBR_DIGESTS=5

# create and/or cleanup the errata dir
ERRATADIR=/tmp/centos-errata
mkdir $ERRATADIR >/dev/null 2>&1
rm -f $ERRATADIR/* >/dev/null 2>&1

(
   cd $ERRATADIR
   # wget needs a proxy? Then set these
   export http_proxy=
   export https_proxy=

   eval `exec /bin/date -u +'yearmon=%Y-%B day=%d'`
   # for the first day of the month: also consider last month
   if [ $day -eq 01 ]; then
      yearmon=`date -u -d '2 days ago' +%Y-%B`\ $yearmon
   fi

   # Use wget to fetch the errata data from centos.org
   listurl=http://lists.centos.org/pipermail/centos
   { for d in $yearmon; do
	  wget --no-cache -q -O- $listurl/$d/date.html \
		| sed -n 's|.*"\([^"]*\)".*CentOS-announce Digest.*|'"$d/\\1|p"
     done
   } |	tail -n $NBR_DIGESTS | xargs -n1 -I{} echo wget -q $listurl/{}

   # the ye old simple way, left as an example for reference:
   #wget --no-cache -q -O- http://lists.centos.org/pipermail/centos/$DATE/date.html| grep "CentOS-announce Digest" |tail -n 5 |cut -d"\"" -f2|xargs -n1 -I{} wget -q http://lists.centos.org/pipermail/centos/$DATE/{}
)

# Set usernames and passwords. You have some options here:
# 1) Either define the environment variables here:
#   export SPACEWALK_USER=my_username
#   export SPACEWALK_PASS=my_passwd
#   export RHN_USER=my_rhn_username
#   export RHN_PASS=my_rhn_password
# 2) Set them on the commandline (but I don't recommend it)
# 3) Set them in a seperate cfg file and source it (like done below)
. ./ya-errata-import.cfg

# now do the import based on the wget results
# !!!! change the channel parameter to your liking
/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --quiet
/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --quiet

# OR do the import and get extra errata info from redhat if possible
# change the channel parameter to your liking
#   and add the option "--redhat-channel <RHN channel name>" if the channel name if not the same as in your spacewalk server
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --get-from-rhn --rhn-proxy=xxx --quiet
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --get-from-rhn --rhn-proxy=xxx --quiet

rm -f $ERRATADIR/*
