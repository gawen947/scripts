#!/bin/sh
# Copyright (c) 2015 David Hauweele <david@hauweele.net>

DEBUG=false

now=$(date +'%s')

select() (echo "$1" | cut -d'=' -f$2)

unban() {
  ban_table=$1
  ban_chain=$2
  iptables=$3

  while read ban
  do
    ip=$(select "$ban" 1)
    limit=$(select "$ban" 2)

    if [ "$now" -gt "$limit" ]
    then
      [ "$DEBUG" = true ] && echo "Unban $ip"
      $iptables -D "$ban_chain" -s "$ip" -j DROP
    fi
  done < "$ban_table"
}

unban /etc/firewall/ip4.ban IP4BAN iptables
unban /etc/firewall/ip6.ban IP6BAN ip6tables
