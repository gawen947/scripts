#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

UP_URL="smeagol.hauweele.net"
UP_PATH="public_html/upload"
DOWN_URL="http://hauweele.net/~$USER/upload"
BASE="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

if [ $# != 1 -a $# != 2 ]
then
  echo "usage: $0 FILE [TTL]"
  exit 1
fi

file=$1

if [ $# = 2 ]
then
    ttl=$2
else
    ttl="1d"
fi

ttl_unit=$(echo $ttl | sed 's/^[[:digit:]]*//')

case "$ttl_unit" in
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

ttl=$(echo $ttl | sed "s/$ttl_unit//")
ttl=$(rpnc $(date +"%s") $ttl $factor . +)

if [ ! -r "$file" ]
then
  echo "cannot read $file"
  exit 1
fi

# This is not 100% percent correct.
# But it should avoid collision in
# most cases.
crc=$(crc32 "$file" | cut -d' ' -f1)
size=$(sizeof -a "$file" | cut -d':' -f2)
upnum=${size}${crc}
upname=$(echo "$upnum" | base -O "$BASE")
filename=$(basename "$file")

# We redirect stdout to stderr so the only line present on stdout is the fetch URL.
rsync --progress --chmod=a+r "$file" $UP_URL:$UP_PATH/$upname 1>&2
ssh $UP_URL "echo $upname $ttl  >> ~/.uploaded-limit; echo \"$upname $filename\" >> ~/.uploaded-map" 1>&2

echo "" 1>&2
echo "Uploaded:" 1>&2
echo "$DOWN_URL/$upname"
