#!/bin/sh

clamp_rate=9999
case "$#" in
  1)
    original_path="$1"
    ;;
  2)
    clamp_rate="$1"
    original_path="$2"
    ;;
  *)
    echo "usage: $0 [[clamp-rate] input-file]"
    exit 1
    ;;
esac

# Parse extension and recompose new path with correct extension.
original_extension=$(echo "$original_path"|awk -F . '{ print $NF }')
new_path=$(dirname "$original_path")/$(basename "$original_path" ."$original_extension").ogg


# Retrieve media information.
info=$(mediainfo "$original_path")

title=$(echo "$info" | grep "Track name  " | head -n1 | sed "s/.*: //")
artist=$(echo "$info" | grep "Performer  " | tail -n1 | sed "s/.*: //")
album=$(echo "$info" | grep "Album  " | head -n1 | sed "s/.*: //")
date=$(echo "$info" | grep "Recorded date  " | head -n1 | sed "s/.*: //")
genre=$(echo "$info" | grep "Genre  " | head -n1 | sed "s/.*: //")
track=$(echo "$info" | grep "Track name/Position  " | head -n1 | sed "s/.*: //")
total=$(echo "$info" | grep "Track name/Total  "  | head -n1 | sed "s/.*: //")
rate=$(echo "$info" | grep "Bit rate" | grep -E -o "[[:digit:]]+ Kbps" | sed "s/ Kbps//")


# Decode
normalized_extension=$(echo "$original_extension" | tr '[:upper:]' '[:lower:]')
decoded=$(mktemp)
rm "$decoded"

# Skip unsupported file formats.
found=""
for supported_extension in ogg flac mp3 wma oga aiff riff wav au mpc m4a aac
do
  if [ "$normalized_extension" = "$supported_extension" ]
  then
    found="$supported_extension"
  fi
done
if [ -z "$found" ]
then
  echo "unsupported extension '$normalized_extension'."
  exit 0
fi

echo "Decoding..."
case "$normalized_extension" in
  mp3)
    #mpg321 -w - -- "$original_path" > "$decoded";;
    decoded="${decoded}.wav"
    ffmpeg -i "$original_path" "$decoded";;
  ogg)
    echo "will not re-encode in the same format."
    exit 0
    ;;
  flac)
    rate="9999"
    flac -d "$original_path" -o "$decoded";;
  *)
    # Fallback to ffmpeg.
    decoded="${decoded}.wav"
    ffmpeg -i "$original_path" "$decoded";;
esac
echo

# Sometimes we cannot decode the rate
if [ -z "$rate" ]
then
  rate="128"
fi

if [ "$rate" -ge "$clamp_rate" ]
then
  echo "clamp from ${rate}Kbps to ${clamp_rate}Kbps"
  rate="$clamp_rate"
fi

# Rate to quality
for equiv_bitrate in 500q10 320q9 256q8 224q7 192q6 160q5 128q4 112q3 96q2 80q1 64q0 45q-1 32q-2
do
  base_rate=$(echo "$equiv_bitrate" | cut -d'q' -f 1)

  if [ "$rate" -ge "$base_rate" ]
  then
    quality=$(echo "$equiv_bitrate" | cut -d'q' -f 2)
    break
  fi
done

# Some stats
echo "Encode from $normalized_extension ${rate}Kbps to Vorbis q$quality ~${base_rate}Kbps"
echo

# Encode
oggenc -t "$title" -a "$artist" -G "$genre" -l "$album" -d "$date" -n "$track/$total" -o "$new_path" -q "$quality" "$decoded"

# Clean
rm "$decoded"
