#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

UP_URL="bilbo.hauweele.net"
UP_PATH="public_html/upload"
DOWN_URL="http://www.hauweele.net/~gawen/upload"
BASE="abcdefghijklmnopqrstuvwxyz0123456789"

if [ $# != 1 ]
then
  echo "usage: $0 FILE"
  exit 1
fi

file=$1

if [ ! -r "$file" ]
then
  echo "cannot read $file"
  exit 1
fi

# This is not 100% percent correct.
# But it should avoid collision in
# most cases.
crc=$(crc32 "$file" | cut -d' ' -f1 | base -O "$BASE")
size=$(sizeof "$file" | cut -d':' -f2 | base -O "$BASE")
upname=${size}${crc}

rsync --progress --chmod=a+r "$file" $UP_URL:$UP_PATH/$upname

echo ""
echo "Uploaded:"
echo "$DOWN_URL/$upname"
