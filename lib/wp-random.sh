#!/bin/sh

if [ $# -lt 3 ]
then
  echo "usage: $(basename $0) sleep-duration directory command [command-args ...]"
  exit 1
fi

sleep_duration="$1"
directory="$2"
shift; shift

while true
do
  wp=$(find "$directory" -type f | sort -R | head -1)
  echo $* "$wp"
  $* "$wp"
  sleep "$sleep_duration"
done
