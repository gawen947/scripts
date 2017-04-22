#!/bin/sh
# Check for upgrades in FreeBSD
export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

echo "Update port tree"
echo "================"
echo
o_pwd=$(pwd)
cd /usr/ports
make update > /dev/null
cd "$o_pwd"
echo "Port tree updated!"

echo
echo "Update repository"
echo "================="
echo
pkg update
echo "Repository updated!"

updates_available=$(mktemp)

echo
echo "Check for new packages"
echo "======================"
echo

pkg version -URl "<" | cut -d' ' -f1 |  sed 's/-[a-zA-Z0-9_\.,]*$//' | while read package
do
  echo " $package"
  rm -f "$updates_available"
done

echo
echo "Check for new ports"
echo "==================="
echo

# They say you shouldn't use port trees and packages at the same time.
# And if you really want to, you should use poudriere instead.
# But some packages default options are completely insane!
# Vim want to install all the gtk stuff on a server.
#
# So I selectively build from ports.
#
# Since we don't have a clean way to ignore packages installed from ports
# in pkg, I just lock them out to avoid pkg complaining about changed options.
locked_packages=$(mktemp)
pkg lock -ql | sed 's/-[a-zA-Z0-9_\.,]*$//' > $locked_packages

pkg version -UIl "<" | cut -d' ' -f1 | sed 's/-[a-zA-Z0-9_\.,]*$//' | while read package
do
  if cat $locked_package | grep "$package" > /dev/null
  then
    echo " $package"
    rm -f "$updates_available"
  fi
done
rm $locked_packages

if [ ! -r "$updates_available" ]
then
  exit 3
else
  rm -f "$updates_available"
  exit 0
fi
