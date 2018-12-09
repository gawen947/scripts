#!/bin/sh
# Copyright (c) 2018 David Hauweele <david@hauweele.net>

no_trail() {
  sed 's/^ *//g' | sed 's/ *$//g'
}

file2track_reg() {
  file="$1"
  regex="$2"
  track=$(echo "$file" | grep -oE "$regex" | grep -oE "[0-9]+" | tail -n1)
  if [ -n "$track" ]
  then
    echo "$track"
    return 0
  else
    return 1
  fi
}

file2track() {
  # Regex used to extract the track number from filename.
  file2track_reg "$1" " - [0-9]+ " && return
  file2track_reg "$1" "^[0-9]+ - " && return
  file2track_reg "$1" "^\([0-9]+\) " && return
  file2track_reg "$1" "^[0-9]+\. " && return
  file2track_reg "$1" "^[0-9]+ " && return
  file2track_reg "$1" "^[0-9]+-" && return
  return 1
}

fix_album_track() {
  album_path="$1"
  dry_run="$2"

  if [ "$dry_run" != "true" ]
  then
    dry_run="false"
  fi

  o_pwd=$(pwd)
  cd "$album_path"

  total=$(ls * | wc -l | no_trail)

  for file in *.ogg
  do
    name=$(basename "$file")
    track=$(file2track "$file") || continue

    if $dry_run
    then
      echo "${track}: $name"
    else
      echo -n "Mark track number $track on '$name'... "
      vorbiscomment -a -t "TRACKNUMBER=$track" "$name"
      echo "done!"
    fi
  done

  cd "$o_pwd"
}

should_fix_track() {
  album_path="$1"

  album_fifo=$(mktemp -u)
  mkfifo "$album_fifo"

  find "$album_path" -type f -name "*.ogg" > "$album_fifo" &

  while read file
  do
    if ! vorbiscomment -l "$file" | grep -i "^TRACKNUMBER=" > /dev/null
    then
      rm "$album_fifo"
      return 0
    fi
  done < "$album_fifo"

  rm "$album_fifo"

  return 1
}

file_size() {
  case "$(uname -s)" in
  FreeBSD) stat -f "%z" "$1";;
  Linux) stat -c "%s" "$1";;
  *)
    echo "unsupported platform :("
    exit 1
    ;;
  esac
}

fix_album_cover() {
  o_pwd=$(pwd)
  cd "$1"

  size=$(file_size "cover.jpg")
  if [ "$size" -gt 1048576 ]
  then
    echo "Cover too large in '$1'."

    if [ -r "orig-cover.jpg" ]
    then
      echo "Alternate cover already exists."
      cd "$o_pwd"
      return
    fi

    echo -n "Convert cover... "
    mv "cover.jpg" "orig-cover.jpg"
    convert "orig-cover.jpg" -quality 75 -resize 30% "cover.jpg"
    chmod 644 "orig-cover.jpg" "cover.jpg"
    echo "done!"
  fi

  cd "$o_pwd"
}

# Albums are any folder with a "cover.jpg" file in it.

find_fifo=$(mktemp -u)
mkfifo "$find_fifo"

find "$1" -type f -name "cover.jpg" > "$find_fifo" &

while read cover <&3
do
  album_path=$(dirname "$cover")

  echo "Checking '$album_path'."

  # Try to fix cover.
  fix_album_cover "$album_path"

  # Try to fix track numbers.
  if should_fix_track "$album_path"
  then
    # Propose dry-run fix.
    echo "Track absent. Proposed fix:"
    echo "-----"
    fix_album_track "$album_path" true
    echo "-----"
    echo -n "Accept? [Y/n] "
    read yn
    case "$yn" in
    [nN]*)
      echo "No fix."
      ;;
    *)
      echo "Starting fix."
      fix_album_track "$album_path" false
      ;;
    esac
    echo
  fi
done 3< "$find_fifo"

rm "$find_fifo"
