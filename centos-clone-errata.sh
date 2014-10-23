#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# This script is meant to be run every day from cron or so.
# The things to edit are between "#### EDIT SECTION x HERE ####" and "#### STOP EDITING SECTION x HERE ####" lines
#    there are 2 sections: one for config variables, one for the different calls to the real script and spacewalk channels

# Changelog
#   10/23/2014: Added the feature to download info about all erratas available in the emails sent to the list. The idea is
#   execute the centos-clone-errata.sh FULL at the first time to load all erratas and every day execute the command
#   centos-clone-errata.sh Digest. <waldirio@gmail.com>
#


# set fixed locale
export LC_ALL=C
export LANG=C

# Global Variables
LogFile="/var/log/errata.log"


#### EDIT SECTION 1 HERE ####
# Set your spacewalk server
SPACEWALK=127.0.0.1

# The number of digests to download (normally there is max 1 errata per day)
# Since the digests are normally only downloaded for 1 month, any number not in the range 1-28 (February) makes no sense
NBR_DIGESTS=5
#### STOP EDITING SECTION 1 HERE ####


menu()
{
  clear
  echo "### Errata Sync ###"
  echo ""
  echo "You may define if you would like to do a Digest Errata Download or"
  echo "if you prefer do a FULL ERRATA DOWNLOAD to your SW environment."
  echo 
  echo "To do a FULL ERRATA DOWNLOAD (recommended only on the first time),"
  echo "you should execute the command # $0 FULL."
  echo
  echo "To do a Digest Errata Dowload (recommended for every day),"
  echo "you should execute the command # $0 Digest."
  echo "Ps.: You have to configure the Digest number inside this file."
}

fullChargeErrata()
{
  # Retrieve all years from emails sent to list, since 2004. This function will sign all erratas from digest
  # available in the mail list.
  allYears=$(curl http://lists.centos.org/pipermail/centos/index.html|grep date.html|cut -d"\"" -f2|cut -d"/" -f1)
  normalChargeErrata FULL "$allYears"
}

normalChargeErrata()
{
  # This function is the same from original, just organized to implement the feature of full erratas.
  if [ $NBR_DIGESTS -lt 1 ]; then
    NBR_DIGESTS=1;
  fi
  if [ $NBR_DIGESTS -gt 28 ]; then
    NBR_DIGESTS=28;
  fi

  # create and/or cleanup the errata dir
  ERRATADIR=/tmp/centos-errata
  [ -d $ERRATADIR ] && rm -f $ERRATADIR/* || mkdir $ERRATADIR

  (
    cd $ERRATADIR

    eval $(exec /bin/date -u +'yearmon=%Y-%B day=%d')
    # for the first day of the month: also consider last month
    # this only applies if the script is ran EVERY DAY
    if [ "$1" == "FULL" ]; then
      yearmon=$2
      TAIL_COMMAND="cat"
    else
      if [ $day -lt $NBR_DIGESTS ]; then
        yearmon=$(date -u -d "$NBR_DIGESTS days ago" +%Y-%B)\ $yearmon
      fi
      TAIL_COMMAND="tail -n $NBR_DIGESTS"
    fi



    # Use wget to fetch the errata data from centos.org
    listurl=http://lists.centos.org/pipermail/centos
    { for d in $yearmon; do
	  wget --no-cache -q -O- $listurl/$d/date.html \
		| sed -n 's|.*"\([^"]*\)".*CentOS-announce Digest.*|'"$d/\\1|p"		| tee -a $LogFile
      done
    } |	$TAIL_COMMAND | xargs -n1 -I{} wget -q $listurl/{}				| tee -a $LogFile

    # the ye old simple way, left as an example for reference:
    #wget --no-cache -q -O- http://lists.centos.org/pipermail/centos/$DATE/date.html| grep "CentOS-announce Digest" |tail -n 5 |cut -d"\"" -f2|xargs -n1 -I{} wget -q http://lists.centos.org/pipermail/centos/$DATE/{}
  )
  errataImport 
}

errataImport()
{
  echo "Errata Import In !!!"
  echo "Errata Dir: $ERRATADIR"

# Set usernames and passwords. You have some options here:
# 1) Either define the environment variables here:
#   export SPACEWALK_USER=my_username
#   export SPACEWALK_PASS=my_passwd
export SPACEWALK_USER=admin
export SPACEWALK_PASS=redhat
#   export RHN_USER=my_rhn_username
#   export RHN_PASS=my_rhn_password
# 2) Set them on the commandline (but I don't recommend it)
# 3) Set them in a separate cfg file and source it (like done below)
##. /etc/ya-errata-import.cfg

# wget needs a proxy? Then set these (or set them also in the config file you used above)
#export http_proxy=
#export https_proxy=

# Command to add errata in channel version 6
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --quiet
./ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos6.5_x86-64_base --os-version 6 --publish	| tee -a $LogFile

# Command to add errata in channel version 5
##/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --quiet

# OR do the import and get extra errata info from redhat if possible
# change the channel parameter to your liking
#   and add the option "--redhat-channel <RHN channel name>" if the channel name if not the same as in your spacewalk server

#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --get-from-rhn --rhn-proxy=xxx --quiet
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --get-from-rhn --rhn-proxy=xxx --quiet


}

# Main
# Test Parameters

if [ "$1" == "FULL" ]; then
  echo "FULL"
  fullChargeErrata
elif [ "$1" == "Digest" ]; then
  echo "Digest"
  normalChargeErrata Digest
elif [ "$1" == "" ]; then
  echo "Menu"
  menu 
else
  echo "Incorrect option"
  exit 1
fi
