#!/bin/sh

export PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

# List all tun IPs (for now I have no way to find out OpenVPN's tun interface).
tun_ip=$(mktemp)
tun_iface=$(ifconfig | grep tun | grep -oE "^[a-z0-9\-]+:" | sed 's/:$//g' | tr '\n' ' ')
for tun in $tun_iface
do
  ifconfig $tun | grep -oE "inet [0-9\.]+" | sed 's/^inet //g' >> "$tun_ip"
  ifconfig $tun | grep -oE "inet6 [0-9a-f:]+ " | sed 's/^inet6 //g' | sed 's/ $//g' >> "$tun_ip"
done
# Don't filter those IPs
echo "::1" >> "$tun_ip"
echo "127.0.0.1" >> "$tun_ip"

# Drop all tcp connections that do not origin from openvpn.
tcpdrop -la | grep -vwf "$tun_ip" | sh

rm "$tun_ip"
