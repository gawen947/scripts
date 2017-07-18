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

auth=""
ssid=""
psk=""
hidden="no"

ask_wifi_params() {
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

  echo "no" >> $hiddenf
  echo "############################" >> $hiddenf
  echo "# Hidden SSID. yes/no      #" >> $hiddenf
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
}

nm_get() {
  conn_id=$1
  field=$2
  echo "$(nmcli -t -m tabular -s -f $field connection show $conn_id)"
}
nm_wifi_params() {
  conn_id="$1"
  ssid="$(nm_get $conn_id 802-11-wireless.ssid)"
  case "$(nm_get $conn_id 802-11-wireless-security.key-mgmt)" in
    "wpa-psk")
      auth="WPA"
      psk="$(nm_get $conn_id 802-11-wireless-security.psk)";;
    "none")
      auth="WEP"
      idx=$(nm_get $conn_id 802-11-wireless-security.wep-tx-keyidx)
      psk="$(nm_get $conn_id 802-11-wireless-security.wep-key$idx)"
      ;;
    *)
      auth="nopass"
  esac
  hidden="$(nm_get $conn_id 802-11-wireless.hidden)"
}

if [ -z "$1" ]
then
  ask_wifi_params
else
  nm_wifi_params "$1"
fi

if [ "$hidden" = "yes" ]
then
  hidden="H:true"
else
  hidden=""
fi

qrcodef=$(mktemp)
qrencode -s 10 -t png -o $qrcodef "WIFI:T:$auth;S:$ssid;P:$psk;$hidden;"
feh $qrcodef
rm $qrcodef
