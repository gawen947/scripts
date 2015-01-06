#!/bin/sh

if [ "$#" = "2" ]
then
  qual=$2
else
  qual=5
fi

ext=$(echo "$1"|awk -F . '{print $NF}')
a=$(dirname "$1" )/$(basename "$1" ".$ext")
info=$(mediainfo "$1")

title=$(echo "$info" | grep "Track name  " | head -n1 | sed "s/.*: //")
artist=$(echo "$info" | grep "Performer  " | tail -n1 | sed "s/.*: //")
album=$(echo "$info" | grep "Album  " | head -n1 | sed "s/.*: //")
date=$(echo "$info" | grep "Recorded date  " | head -n1 | sed "s/.*: //")
genre=$(echo "$info" | grep "Genre  " | head -n1 | sed "s/.*: //")
track=$(echo "$info" | grep "Track name/Position  " | head -n1 | sed "s/.*: //")
total=$(echo "$info" | grep "Track name/Total  "  | head -n1 | sed "s/.*: //")
rate=$(echo "$info" | grep "Bit rate" | grep -E -o "[[:digit:]]+ Kbps" | sed "s/ Kbps//")

tmp=$(TMPDIR=. mktemp)
rm $tmp
tmp=${tmp}.wav

ffmpeg -i "$1" $tmp
oggenc -t "$title" -a "$artist" -G "$genre" -l "$album" -d "$date" -n "$track" -o "$a.ogg" -q $qual $tmp
rm $tmp
