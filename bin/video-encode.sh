#!/bin/sh
# Copyright (c) 2012-2019 David Hauweele <david@hauweele.net>

if [ $# -lt 4 ]
then
  echo "usage: $0 <input-file> <output-file> <vcodec:quality/bitrate<:tune>> <acodec:quality/bitrate> [subfix|nosub|2pass]"
  exit 1
else
  file="$1"
  output="$2"
  vfield="$3"
  afield="$4"
fi

shift; shift; shift; shift

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
  vqual=1200k
fi

aqual=$(echo $afield | cut -d':' -f 2)
acodec=$(echo $afield | cut -d':' -f 1)
if [ "$aqual" = "$afield" ]
then
  aqual=2
fi

# Any quality that doesn't end with a number isn't an abstract
# quality value but a bitrate (since all bitrate are at least 
# expressed in kbps.
if echo "$vqual" | grep "[0-9]$" > /dev/null
then
  vqual_type=quality
else
  vqual_type=bitrate
fi

case "$vcodec" in
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

    v_part="-codec:v libx264 -preset slow -tune $vtune";;
  [hx]265)
    # X265
    #  Same as X264 basically...
    #  But we don't have tune for films.
    v_part="-codec:v libx265 -preset slow";;
  copy)
    v_part="-codec:v copy";;
  *)
    echo "Unrecognised video codec \"$vcodec\", availables are vpx, copy"
    exit 1
    ;;
esac

case "$vqual_type" in
  quality)
    v_part="$vpart -crf $vqual";;
  bitrate)
    v_part="$vpart -b:v $vqual";;
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

e_2pass=false
for extra in $*
do
  case "$extra" in
    "") ;;
    subfix)
      sub_part="-c:s copy";;
    nosub)
      sub_part="-sn";;
    2pass)
      e_2pass=true;;
    *)
      echo "Unrecognied extra parameter"
      exit 1
      ;;
  esac
done


infile="$file"
outfile="$output"

outext=$(echo "$outfile" | awk -F . '{print $NF}')
outnoext=$(basename "$outfile" .$outext)
encfile=$(mktemp -u "$outnoext.encoding.XXXXXXXXXX")
rm -f "$encfile"
encfile="$encfile.mkv"

if $e_2pass
then
  echo "2-pass encoding"
  echo "---------------"
  echo

  pass1_file=$(mktemp -u "$outnoext.encoding.XXXXXXXXXX")
  rm -f "$pass1_file"
  pass1_file="$pass1_file.mkv"

  pass_log=$(mktemp -u "$outnoext.encoding.XXXXXXXXXX")
  rm -f "$pass_log"
  pass_log="$pass_log.pass.log"

  cmd_1="ffmpeg -i \"$infile\" -pass 1 -passlogfile \"$pass_log\" $sub_part -map 0 $v_part $a_part \"$pass1_file\""
  echo "pass 1"
  echo "------"
  echo
  echo $cmd_1
  eval $cmd_1 < /dev/null
  if [ "$?" != 0 ]
  then
    rm -f "$pass1_file"
    rm -f "$pass_log"
    echo "Failed!"
    exit 1
  fi

  cmd_2="ffmpeg -i \"$infile\" -pass 2 -passlogfile \"$pass_log\" $sub_part -map 0 $v_part $a_part \"$encfile\""
  echo "pass 2"
  echo "------"
  echo
  echo $cmd_2
  eval $cmd_2 < /dev/null
  if [ "$?" != 0 ]
  then
    rm -f "$pass1_file"
    rm -f "$pass_log"
    rm -f "$encfile"
    echo "Failed!"
    exit 1
  fi

  rm -f "$pass1_file"
  rm -f "$pass_log"*
  mv "$encfile" "$outfile"
else
  echo "1-pass encoding"
  echo "---------------"
  echo

  cmd="ffmpeg -i \"$infile\" $sub_part -map 0 $v_part $a_part \"$encfile\""
  echo $cmd
  eval $cmd < /dev/null
  if [ "$?" = 0 ]
  then
    mv "$encfile" "$outfile"
  else
    rm -f "$encfile"
    echo "Failed!"
    exit 1
  fi
fi

exit 0
