#!/bin/sh
#
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

if ! which qrencode > /dev/null
then
  echo "error: requires qrencode"
  exit 1
fi

if ! which feh > /dev/null
then
  echo "error: requires feh"
  exit 1
fi

authf=$(mktemp)
ssidf=$(mktemp)
pskf=$(mktemp)
hiddenf=$(mktemp)

echo "nopass" >> $authf
echo "############################" >> $authf
echo "# Authentification method. #" >> $authf
echo "#                          #" >> $authf
echo "# WEP, WPA, nopass         #" >> $authf
echo "############################" >> $authf

echo "" >> $ssidf
echo "############################" >> $ssidf
echo "# SSID name.               #" >> $ssidf
echo "############################" >> $ssidf

echo "" >> $pskf
echo "############################" >> $pskf
echo "# Preshared key.           #" >> $pskf
echo "############################" >> $pskf

echo "false" >> $hiddenf
echo "############################" >> $hiddenf
echo "# Hidden SSID.             #" >> $hiddenf
echo "############################" >> $hiddenf

vim $authf
vim $ssidf
auth="$(grep . $authf | grep -v '^#')"

if [ -z "$auth" ]
then
  auth="nopass"
fi

if [ "$auth" != "nopass" ]
then
  vim $pskf
fi

vim $hiddenf


ssid="$(grep . $ssidf | grep -v '^#')"
psk="$(grep . $pskf | grep -v '^#')"
hidden="$(grep . $hiddenf | grep -v '^#')"

rm $pskf
rm $ssidf
rm $hiddenf
rm $authf

if [ "$hidden" = "true" ]
then
  hidden="H:true"
else
  hidden=""
fi

qrcodef=$(mktemp)
qrencode -s 10 -t png -o $qrcodef "WIFI:T:$auth;S:$ssid;P:$psk;$hidden;"
feh $qrcodef
rm $qrcodef
