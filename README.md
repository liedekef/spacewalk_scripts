ya-errata-import is a new script to import EPEL, CentOS, RedHat, Scientific
Linux and Oracle Linux errata into spacewalk. I created this to solve most
of my frustrations with existing errata import scripts:
- we have redhat and centos packages in spacewalk, both can have the same
  package names, which would result in redhat packages being pushed in centos
  channels because of the errata create (and thus everything fails)
  Almost every python script has this problem (and some perl scripts too)
- the XML file of errata-import.pl is ok, but updated by one person and only
  for security errata (I think)
- errata-import.pl had good code, but no RHN integration, and is too easy
  for missing packages (if 1 package from the errata is there, the errata is
  created, while other packages might be missing)
- always different scripts were created/used for redhat and centos errata
- most perl scripts lacked proxy support

So, my script (well, combo of shell and perl) was born:

For CentOS:
- first some shell calls to get the latest announces from the centos archive
  (but not by scraping the announces list, but getting digests, much less
  traffic then)
  You can change the number of announces anyway you want by changing the
  wget command to your liking
- then the perl script comes along, parsing the digest files and looking in 1
  channel (yes, one) for package availability and creating the errata there.
  It has optional integration with RHN for notes, description, topic info, and
  CVE's and/or can use the OVAL file like the errata-import.pl script does.
  The created errata gets a suffix based on the OS version and architecture
  (e.g. ":C5-64" or ":C6-32"), because the same errata can exist for multiple
  OS versions and architectures (and creating the errata for more than one
  base channel would result in packages being copied which is a mess again).
  Also a proxy can be defined for spacewalk and or RHN servers

For RedHat:
- log in to RHN, get the errata for the specified channel
  (possibility to define the date range)
- then follow the same logic as for CentOS

For EPEL:
- first some shell calls (see the example epel-clone-errata.sh) that downloads
  the updateinfo.xml.gz from fedora
- then the perl script comes along, parsing the xml file and looking in 1
  channel (yes, one) for package availability and creating the errata there.
  The created errata gets a suffix based on the OS version and architecture
  (e.g. ":C5-64" or ":R6-32"), because the same errata can exist for multiple
  OS versions and architectures (and creating the errata for more than one
  base channel would result in packages being copied which is a mess again).
  To make sure that you can push the same errata for redhat and centos channels,
  you can use the --redhat option, so the suffix will be like ":R6-32", otherwise
  it will be like ":C6-32"

Dependencies:
- on RHEL 6, the following packages are needed in order to make the proxy work
  with RHN packages:

  perl-Socket6
  perl-IO-Socket-INET6
  perl-Net-INET6Glue
  perl-Crypt-SSLeay
  
######
Changelog:

10/23/2014: Was included the feature to add in Spacewalk all erratas we can retrieve from mail list.
