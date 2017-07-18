#!/bin/sh
#  Copyright (c) 2013, David Hauweele <david@hauweele.net>
#  All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions are met:
#
#   1. Redistributions of source code must retain the above copyright notice, this
#      list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

auth=""
ssid=""
psk=""
hidden="no"

check_binary() {
  binary=$1
  package=$2

  if [ -z "$package" ]
  then
    package=$binary
  fi

  if ! which "$binary" > /dev/null
  then
    >&2 echo "error: missing dependency $package"
    exit 1
  fi
}

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

check_binary qrencode qrencode
check_binary feh feh

method="$1"
if [ $# = 0 ]
then
  method=ask
fi
shift

case "$method" in
  ask)
    check_binary vim vim

    ask_wifi_params
    ;;
  nm)
    check_binary nmcli network-manager

    nm_wifi_params "$1"
    ;;
  *)
    echo "usage: $(basename $0) [method [...]]"
    echo
    echo "Methods:"
    echo "  ask            Ask for WiFi parameters."
    echo "  nm  [conn-id]  Fetch parameters using network-manager."
    exit 1
    ;;
esac

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
