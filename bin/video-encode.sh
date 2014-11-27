#!/bin/sh
# Copyright (c) 2012 David Hauweele <david@hauweele.net>

if [ $# != 3 ]
then
  echo "usage: $0 <file> <vcodec:quality> <acodec:quality>"
  exit 1
fi

file="$1"
vfield="$2"
afield="$3"

if [ ! \( -f "$file" -a -r "$file" \) ]
then
  echo "cannot read $file"
  exit 1
fi

vqual=$(echo $vfield | cut -d':' -f 2)
vcodec=$(echo $vfield | cut -d':' -f 1)
if [ "$vqual" = "$vfield" ]
then
  vqual=1000
fi

aqual=$(echo $afield | cut -d':' -f 2)
acodec=$(echo $afield | cut -d':' -f 1)
if [ "$aqual" = "$afield" ]
then
  aqual=2
fi

vqual=${vqual}k
case "$vcodec"
  in
  vp8|vpx)
    v_part="-codec:v libvpx -quality good -cpu-used 0 -b:v $vqual";;
  copy)
    v_part="-codec:v copy";;
  *)
    echo "Unrecognised video codec \"$vcodec\", availables are vpx, copy"
    exit 1
    ;;
esac

case "$acodec"
  in
  ogg|vorbis)
    a_part="-codec:a libvorbis -q:a $aqual";;
  flac)
    a_part="-codec:a flac";;
  copy)
    a_part="-codec:a copy";;
  *)
    echo "Unrecognised audio codec \"$acodec\", availables are ogg, flac, copy"
    exit 1
    ;;
esac

opwd=$(pwd)
basedir=$(dirname "$file")
basefile=$(basename "$file")
cd "$basedir"
mkdir -p ".encoded"
noextension=$(basename "$basefile" .$(echo "$basefile" | awk -F . '{print $NF}'))
newfile=$(mktemp -u "$noextension-encoding-XXXXXXXXXX")
rm -f "$newfile"
newfile=${newfile}.mkv
cmd="ffmpeg -i \"$basefile\" -map 0 $v_part $a_part \"$newfile\""
echo $cmd
eval $cmd
if [ "$?" = 0 ]
then
  mv $basefile .encoded
  mv $newfile $noextension.mkv
else
  rm $newfile
  echo "Failed!"
  exit 1
fi

cd $opwd
