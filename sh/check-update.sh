#! /bin/sh
#export http_proxy="http://10.16.1.3:3128"
#export https_proxy="http://10.16.1.3:3128"
#export ftp_proxy="http://10.16.1.3:3128"

apt-get clean
apt-get update 

apt-get --dry-run upgrade |
tee apt-upgrade-list.txt |
tee u3

apt-cache dumpavail >apt-cache-dump.txt
grep "^Package: " apt-cache-dump.txt >P

dpkg -l >dpkg-list.txt

echo "press ENTER for upgrade or ^C for cancel"
apt-get upgrade
