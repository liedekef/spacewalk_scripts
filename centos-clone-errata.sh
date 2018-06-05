#!/bin/bash
# Processes CentOS Errata and imports it into Spacewalk

# IMPORTANT: read through this script, it's more of a guidance than something fixed in stone
# This script is meant to be run every day from cron or so.
# The things to edit are between "#### EDIT SECTION x HERE ####" and "#### STOP EDITING SECTION x HERE ####" lines
#    there are 2 sections: one for config variables, one for the different calls to the real script and spacewalk channels

# set fixed locale
export LC_ALL=C
export LANG=C

#### EDIT SECTION 1 HERE ####

SCRIPTNAME=$(basename ${0})
THISDATE=$(date +%F)
LOGPATH='/tmp/errata-import'
LOGFILE="${LOGPATH}/${SCRIPTNAME}.log"
LOCKFILE="/var/run/${SCRIPTNAME}.lck"
SUPPORTEMAIL="me@you.com"
# UPDATE THESE TO YOUR CHANNEL NAMES
CHANNELSTOCONSIDER="centos5-x86_64-all
centos6-x86_64-all
centos7-x86_64-all"

# Trap a Ctrl-C to clean up the lock file
trap ctrl_c INT TERM
function ctrl_c(){
        echo '*** TRAPPED CTRL-C ***' >> "${LOGFILE}"
        rm "${LOCKFILE}" && exit 1
}

if [ -f "${LOCKFILE}" ]; then
        echo "Lock file exists at ${LOCKFILE}, exiting!" | tee -a "${LOGFILE}"
        exit 1
else
        echo "${SCRIPTNAME} started on $(date)" | tee -a "${LOCKFILE}"
fi

echo "${THISDATE} - Starting ${SCRIPTNAME}"

# Set your spacewalk server
SPACEWALK=127.0.0.1

# The number of digests to download (normally there is max 1 errata per day)
# Since the digests are normally only downloaded for 1 month, any number not in the range 1-28 (February) makes no sense
NBR_DIGESTS=5

# Set usernames and passwords. You have some options here:
# 1) Either define the environment variables here:
#   export SPACEWALK_USER=my_username
#   export SPACEWALK_PASS=my_passwd
#   export RHN_USER=my_rhn_username
#   export RHN_PASS=my_rhn_password
# 2) Set them on the commandline (but I don't recommend it)
# 3) Set them in a separate cfg file and source it (like done below)
. /etc/ya-errata-import.cfg

# wget needs a proxy? Then set these (or set them also in the config file you used above)
#export http_proxy=
#export https_proxy=

#### STOP EDITING SECTION 1 HERE ####

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
   if [ $day -lt $NBR_DIGESTS ]; then
      yearmon=$(date -u -d "$NBR_DIGESTS days ago" +%Y-%B)\ $yearmon
   fi

   # Use wget to fetch the errata data from centos.org
   listurl=https://lists.centos.org/pipermail/centos
   { for d in $yearmon; do
	  wget --no-cache -q -O- $listurl/$d/date.html \
		| sed -n 's|.*"\([^"]*\)".*CentOS-announce Digest.*|'"$d/\\1|p"
     done
   } |	tail -n $NBR_DIGESTS | xargs -n1 -I{} wget -q $listurl/{}
   # Also scrape the actual CentOS-announce mailing list since the digests are not completely reliable
   listurl=https://lists.centos.org/pipermail/centos-announce
   { for d in $yearmon; do
 	  wget --no-cache -q -O- $listurl/$d/date.html \
 		| sed -n 's|.*"\([^"]*\)".*\[CentOS-announce\].*CE.A.*|'"$d/\\1|p"
     done
   } | tail -n $NBR_DIGESTS | xargs -n1 -I{} wget -q $listurl/{} 

   # Also scrape the CentOS-CR-announce mailing list since the digests are not completely reliable
   listurl=https://lists.centos.org/pipermail/centos-cr-announce
   { for d in $yearmon; do
          wget --no-cache -q -O- $listurl/$d/date.html \
                | sed -n 's|.*"\([^"]*\)".*\[CentOS-CR-announce\].*CE.A.*|'"$d/\\1|p"
     done
   } | tail -n $NBR_DIGESTS | xargs -n1 -I{} wget -q $listurl/{}

   # the ye old simple way, left as an example for reference:
   #wget --no-cache -q -O- https://lists.centos.org/pipermail/centos/$DATE/date.html| grep "CentOS-announce Digest" |tail -n 5 |cut -d"\"" -f2|xargs -n1 -I{} wget -q http://lists.centos.org/pipermail/centos/$DATE/{}
)

LOGFILE=/var/log/rhn/shc/errata-import/ya-errata-import.sh.log
REDHATERRATAURL='https://www.redhat.com/security/data/oval/com.redhat.rhsa-all.xml'
OVALPATH="${ERRATADIR}/com.redhat.rhsa-all.xml"
/usr/bin/wget -O"${OVALPATH}" -N "${REDHATERRATAURL}" >>"${LOGFILE}" 2>&1
if [ $? -ne 0 ]; then
        echo "Download of ${REDHATERRATAURL} failed!">>"${LOGFILE}"
        echo -e "${THISDATE} - ${0} failed!\n" | mailx -a "${LOGFILE}" -s "Spacewalk errata download error!" "${SUPPORTEMAIL}"
fi

#### EDIT SECTION 2 HERE ####

# now do the import based on the wget results
# !!!! change the channel parameter to your liking
# /sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --quiet
# /sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --quiet

for CHANNEL in ${CHANNELSTOCONSIDER}; do
	# Modify below to extract the OSVER from your channel name (you are using standardized names, right?), or use the above method of one line per import operation
	OSVER=$(echo "${CHANNEL}" | awk -F- '{print $1}' | sed 's/[[:alpha:]]//g')
	/usr/local/bin/ya-errata-import.pl --erratadir="${ERRATADIR}" --server "${SPACEWALK}" --channel "${CHANNEL}" --os-version "${OSVER}" --publish --rhsa-oval "${OVALPATH}" >>"${LOGFILE}" 2>&1
done

# OR do the import and get extra errata info from redhat if possible
# change the channel parameter to your liking
#   and add the option "--redhat-channel <RHN channel name>" if the channel name if not the same as in your spacewalk server
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-6 --os-version 6 --publish --get-from-rhn --rhn-proxy=xxx --quiet
#/sbin/ya-errata-import.pl --erratadir=$ERRATADIR --server $SPACEWALK --channel centos-x86_64-server-5 --os-version 5 --publish --get-from-rhn --rhn-proxy=xxx --quiet

#### STOP EDITING SECTION 2 HERE ####

rm -f $ERRATADIR/*
rm "${LOCKFILE}"
