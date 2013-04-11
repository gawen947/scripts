#!/bin/sh
# Copyright (c) 2010 David Hauweele <david@hauweele.net

if [ ! "$#" = "2" ]
then
  echo "Usage: $(basename $0) IMAGE QUALITY"
  exit 1
fi

extension="$(echo $1 | awk -F . '{print $NF}')"
base=$(basename "$1" .$extension)
cwebp "$1" -m 6 -q "$2" -o "$base.webp"
