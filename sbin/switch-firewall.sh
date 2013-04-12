#!/bin/sh
# Copyright (c) 2012 David Hauweele <david@hauweele.net>

# Command line
if [ -z "$1" ]
then
  profil=default
else
  profil=$1
fi

# Sanity filter
profil=$(echo $profil | tr -dc "[a-z]")

# Profil check
firewall_path=/etc/firewall/$profil
if [ ! -x "$firewall_path" ]
then
  echo "error: profil \"$profil\" does not exist"
  exit 1
fi

echo -n "Clean... "
modprobe ip_tables
modprobe ip6_tables
modprobe ip6table_filter
echo 1 > /proc/sys/net/ipv4/conf/all/rp_filter
iptables -F
iptables -X
ip6tables -F
ip6tables -X
echo "done!"

echo "Switch to" $profil
newcmd=$firewall_path

for arg in $*
do
  if [ $i != 0 ]
  then
    newcmd="$newcmd $arg"
  fi
done

$newcmd
echo "$profil" > /etc/firewall.current
