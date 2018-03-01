#!/bin/sh
# Copyright (c) 2015 David Hauweele <david@hauweele.net>

# Note: for now it only supports iptables (Linux) and PF (*BSD)
#       but anyone with a patch would be welcome.

set -e

case "$(uname -s)" in
  *BSD)
    # PF made it EZ
    # A periodic script unban IPs with a fixed timeout:
    #   pfctl -t banned -T expire 86400
    # A shutdown script save IPs in the /etc/ip.ban file.
    #   /etc/rc.shutdown: pfctl -t banned -T show > /etc/ip.ban
    pfctl -t banned -T add "$1"
    pfctl -k "$1"
    exit 0
    ;;
  *)
    # default on Netfilter
    ;;
esac

IP4_BAN_TABLE=/etc/firewall/ip4.ban
IP6_BAN_TABLE=/etc/firewall/ip6.ban

IP4_BAN_CHAIN=IP4BAN
IP6_BAN_CHAIN=IP6BAN

if [ $# != 2 ]
then
  echo "usage: $(basename $0) ip limit"
  exit 1
fi

# FIXME: check that ip is valid.
ip=$1
limit=$2

unit=$(echo $limit | sed 's/^[[:digit:]]*//')

case "$unit" in
  s) factor=1;;
  m) factor=60;;
  h) factor=3600;;
  d) factor=86400;;
  w) factor=604800;;
  y) factor=31536000;;
  *)
    echo "Unknown ttl unit."
    echo "Did you mean:"
    echo " s - seconds ?"
    echo " m - minutes ?"
    echo " h - hours ?"
    echo " d - days ?"
    echo " w - weeks ?"
    echo " y - years ?"
    exit 1
    ;;
esac

limit=$(echo $limit | sed "s/$unit//")
limit=$(rpnc $(date +'%s') $limit $factor . +)

if echo "$ip" | grep ':' > /dev/null
then
  ban_table=$IP6_BAN_TABLE
  ban_chain=$IP6_BAN_CHAIN
  iptables=ip6tables
else
  ban_table=$IP4_BAN_TABLE
  ban_chain=$IP4_BAN_CHAIN
  iptables=iptables
fi

$iptables -I "$ban_chain" -s "$ip" -j DROP
echo "${ip}=${limit}" >> "$ban_table"

echo "Banned $ip!"
