#!/bin/sh
# Copyright (c) 2012 David Hauweele <david@hauweele.net>

if [ $# = 4 ]
then
  file="$1"
  output="$2"
  vfield="$3"
  afield="$4"
elif [ $# = 5 ]
then
  file="$1"
  output="$2"
  extra="$3"
  vfield="$4"
  afield="$5"
else
  echo "usage: $0 <input-file> <output-file> [subfix/nosub] <vcodec:quality<:tune>> <acodec:quality>"
  exit 1
fi

if [ ! \( -f "$file" -a -r "$file" \) ]
then
  echo "cannot read $file"
  exit 1
fi

vtune=$(echo $vfield | cut -d':' -f 3)
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

case "$vcodec"
  in
  vp9|vpx)
    v_part="-codec:v libvpx -quality good -cpu-used 0 -crf 5 -qmin 0 -qmax 50 -b:v $vqual";;
  vp8)
    v_part="-codec:v libvpx -quality good -cpu-used 0 -crf 5 -qmin 0 -qmax 50 -b:v $vqual";;
  vp3|theora)
    v_part="-codec:v libtheora -b:v $vqual";;
  [hx]264)
    # X264
    #  Video quality: 0 - 51 (recommended 18-28 or 20-22)
    #  Tune can be film or anime or others
    if [ -z "$vtune" ]
    then
      echo "expect tune from:"
      echo "film animation grain stillimage psnr ssim fastdecode zerolatency"
      exit 1
    fi

    v_part="-codec:v libx264 -preset slow -crf $vqual -tune $vtune";;
  [hx]265)
    # X265
    #  Same as X264 basically...
    #  But we don't have tune for films.
    v_part="-codec:v libx265 -preset slow -crf $vqual";;
  copy)
    v_part="-codec:v copy";;
  *)
    echo "Unrecognised video codec \"$vcodec\", availables are vpx, copy"
    exit 1
    ;;
esac

case "$acodec" in
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

case "$extra" in
  subfix)
    sub_part="-c:s copy";;
  nosub)
    sub_part="-sn";;
  *)
    echo "Unrecognied extra parameter"
    exit 1
    ;;
esac

infile="$file"
outfile="$output"

outext=$(echo "$outfile" | awk -F . '{print $NF}')
outnoext=$(basename "$outfile" .$outext)
encfile=$(mktemp -u "$outnoext.encoding.XXXXXXXXXX")
rm -f "$encfile"
encfile="$encfile.mkv"

cmd="ffmpeg -i \"$infile\" $sub_part -map 0 $v_part $a_part \"$encfile\""
echo $cmd
eval $cmd < /dev/null
if [ "$?" = 0 ]
then
  mv "$encfile" "$outfile"
else
  rm "$encfile"
  echo "Failed!"
  exit 1
fi

exit 0
