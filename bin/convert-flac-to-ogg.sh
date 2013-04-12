#!/bin/sh
# Copyright (c) 2013 David Hauweele <david@hauweele.net>

if [ "$#" = "2" ]
then
  qual=$2
else
  qual=5
fi

ext=$(echo "$1"|awk -F . '{print $NF}')
a=$(basename "$1" ".$ext")
info=$(mediainfo "$1")

title=`metaflac --show-tag="title" "$a.flac" | sed "s/.*=//"`
artist=`metaflac --show-tag="artist" "$a.flac" | sed "s/.*=//"`
album=`metaflac --show-tag="album" "$a.flac" | sed "s/.*=//"`
date=`metaflac --show-tag="date" "$a.flac" | sed "s/.*=//"`
genre=`metaflac --show-tag="genre" "$a.flac" | sed "s/.*=//"`
track=`metaflac --show-tag="tracknumber" "$a.flac" | sed "s/.*=//"`

flac -c -d "$a.flac" | oggenc -t "$title" -a "$artist" -G "$genre" -l "$album" -d "$date" -n "$track" -o "$a.ogg" -q $qual -
