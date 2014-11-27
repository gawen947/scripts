#!/bin/sh
# Copyright (c) 2012 David Hauweele <david@hauweele.net>

ENCODED="encoded"

if [ $# = 3 ]
then
  file="$1"
  vfield="$2"
  afield="$3"
elif [ $# = 4 ]
then
  file="$1"
  output="$2"
  vfield="$3"
  afield="$4"
else
  echo "usage: $0 <input-file> [output-file] <vcodec:quality> <acodec:quality>"
  exit 1
fi


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
    v_part="-codec:v libvpx -quality good -cpu-used 0 -crf 5 -qmin 0 -qmax 50 -b:v $vqual";;
  vp3|theora)
    v_part="-codec:v libtheora -b:v $vqual";;
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
mkdir -p "$ENCODED"
noextension=$(basename "$basefile" .$(echo "$basefile" | awk -F . '{print $NF}'))
newfile=$(mktemp -u "$noextension-encoding-XXXXXXXXXX")
rm -f "$newfile"
newfile=${newfile}.mkv
cmd="ffmpeg -i \"$basefile\" -map 0 $v_part $a_part \"$newfile\""
echo $cmd
eval $cmd
if [ "$?" = 0 ]
then
  mv "$basefile" "$ENCODED"
  if [ -n "$output" ]
  then
    mv "$newfile" "$output"
  else
    mv "$newfile" "$noextension.mkv"
  fi
else
  rm $newfile
  echo "Failed!"
  exit 1
fi

cd $opwd
