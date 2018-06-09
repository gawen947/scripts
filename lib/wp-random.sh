#!/bin/sh

if [ $# != 3 ]
then
  echo "usage: $(basename $0) sleep-duration command directory"
  exit 1
fi

sleep_duration="$1"
command_exec="$2"
directory="$3"

while true
do
  wp=$(find "$directory" -type f | sort -R | head -1)
  echo $command_exec "$wp"
  $command_exec "$wp"
  sleep "$sleep_duration"
done
