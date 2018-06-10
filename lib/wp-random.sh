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

if [ ! -d "$directory" ]
then
  echo "Not a directory."
  exit 1
fi

redraw_wp() {
  echo $* "$wp"
  $* "$wp"
}

dummy() {
}

# SIGUSR1 redraws the wallpaper (for example when you turn on VGA)
# SIGUSR2 select another wallpaper
trap "redraw_wp $*; wait" USR1
trap "dummy" USR2

while true
do
  wp=$(find -L "$directory" -type f | sort -R | head -1)
  redraw_wp $*
  sleep "$sleep_duration" &
  wait
done
