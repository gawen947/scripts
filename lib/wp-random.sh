#!/bin/sh

if [ $# -lt 3 ]
then
  echo "usage: $(basename $0) sleep-duration directory command [command-args ...]"
  exit 1
fi

# Check that they aren't any other daemon running.
# If there is, we kill him.
pid_file="/tmp/wp-random_$DISPLAY.pid"
if [ -r "$pid_file" ]
then
  echo "Existing wp-random daemon found. Killing it."
  kill -TERM $(cat "$pid_file")
fi
echo "$$" > "$pid_file"

sleep_duration="$1"
directory="$2"
shift; shift

while true
do
  wp=$(find "$directory" -L -type f | sort -R | head -1)
  echo $* "$wp"
  $* "$wp"
  sleep "$sleep_duration"
done
