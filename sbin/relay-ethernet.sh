#!/bin/sh
# Copyright (c) 2012 David Hauweele <david@hauweele.net>

case $1 in
start)
  echo "Enabling internet relay..."
  cp   /etc/network/interfaces.relay /etc/network/interfaces
  echo "You should reboot now if you haven't done so."
#  find /proc/ -name "*forward*" -exec sh -c "echo 1 > {}" \;
  iptables -F
  iptables -P INPUT ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -P FORWARD ACCEPT
  dnsmasq -d -q -i eth0 -K
  ;;
stop)
  echo "Disabling internet relay..."
  cp /etc/network/interfaces.full /etc/network/interfaces
  echo "Done... You should reboot now."
  ;;
esac
