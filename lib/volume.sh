#!/bin/sh
# Copyright (c) 2011-2013 David Hauweele <david@hauweele.net>

CONFIGURATION=$HOME/.volume
if [ -r "$CONFIGURATION" ]
then
  . "$CONFIGURATION"
else
  echo "Cannot read the configuration file at '$CONFIGURATION'."
  exit 1
fi

DISPLAY_PID="/tmp/.volume.aosd_$(hostname)_$USER.pid"

display() (
  if [ "$OSD" = false ]
  then
    exit 0
  fi

  if [ -r "$DISPLAY_PID" ]
  then
    kill -TERM $(cat "$DISPLAY_PID")
  fi

  type=$1
  value=$2

  case "$1" in
    volume)
      echo $OSD_TEXT_VOLUME | sed "s/##VALUE##/$value/" | $OSD_VOLUME --font="$OSD_FONT" &;;
    off)
      echo $OSD_TEXT_OFF | $OSD_OFF --font="$OSD_FONT" &;;
    on)
      echo $OSD_TEXT_ON | $OSD_ON --font="$OSD_FONT" &;;
    *)
      echo "error: unknown type";;
  esac

  pid=$!
  echo $pid > "$DISPLAY_PID"
  if wait $pid
  then
    rm "$DISPLAY_PID"
  fi
)

check_volume() (
  volume=$1

  if [ $volume -gt "$MAX_VOLUME" ]
  then
    echo $MAX_VOLUME
  elif [ $volume -lt "$MIN_VOLUME" ]
  then
    echo $MIN_VOLUME
  else
    echo $volume
  fi
)

# Each method here will add the argument given in percent to the current volume.
# This can be a negative number.
pulse_audio() (
  add=$1

  # Get the current volume in percent
  current_volume=$(pacmd dump-volumes | grep "Sink $SINK" | cut -d':' -f 3 | grep -E -o "[[:digit:]]+" | head -n 1)

  target_volume=$(rpnc $current_volume $add +)
  target_volume=$(check_volume $target_volume)

  pactl set-sink-volume "$SINK" "$target_volume%"
  display volume "$target_volume" &
)

# These commands switch the mute value
pulse_audio_mute() (
  # The peoples behind the "pacmd" command are pretty much brain damaged.
  # We cannot extract anything easily so the command is completely useless.
  # The whole information seems structured in such a way that we cannot
  # parse it easily without any ugly workaround.
  # Here we just want to know if "Sink 0" is muted or not...
  muted=$(pacmd info | tr '\n' '|' | sed 's/|[0-9]* sink(s) available\./\n/' | sed 's/|[0-9]* source(s) available\./\n/' | head -n 2 | tail -n 1 | sed 's/index:/\n##SINK##/' | grep "##SINK## $SINK" | grep -E -o "muted: (yes|no)")

  if [ "$muted" = "muted: yes" ]
  then
    target_mute=0
    display on &
  elif [ "$muted" = "muted: no" ]
  then
    target_mute=1
    display off &
  else
    echo "error: cannot extract muted value"
    exit 1
  fi

  pactl set-sink-mute $SINK $target_mute
)

if [ $# != 1 ]
then
  echo "usage: $0 switch|+/-<percent>"
  exit 1
fi

case "$METHOD" in
  pulse)
    vol_cmd=pulse_audio;;
  *)
    echo "error: unknown method"
    exit 1
    ;;
esac
vol_mute=${vol_cmd}_mute

if [ "$1" = switch ]
then
  $vol_mute || exit 1
else
  if [ "$1" = "+" ]
  then
    value="+$INCREMENT"
  elif [ "$1" = "-" ]
  then
    value="-$INCREMENT"
  else
    value="$1"
  fi

  $vol_cmd "$value"
fi
