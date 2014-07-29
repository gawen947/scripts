#!/bin/sh
#
# Copyright (c) 2014 David Hauweele <david@hauweele.net>

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

if [ -n "$1" ]
then
  string="$1"
else
  echo -n "QRCode content: "
  read string
fi

qrcodef="$(mktemp)"
qrencode -s 10 -t png -o $qrcodef "$string"
feh $qrcodef
rm $qrcodef
