#!/bin/sh
# Copyright (c) 2011 David Hauweele <david@hauweele.net>

IVAL=$(base -i 16 -o 10 -- $IVAL)

A=$(pacmd dump | grep "set-sink-volume alsa_output.pci-0000_00_1b.0.analog-stereo" | cut -d " " -f 3 | cut -d'x' -f 2 | base -i 16 -o 10 --)

if [ -z "$A" ]
then
  echo "Cannot extract sound level..."
  exit 1
fi

B=$(gcalc $A $IVAL +)

if $(test $B -lt 0)
then
  B=0
fi

OVAL="0x$(base -i 10 -o 16 -- $B)"
pactl set-sink-volume 0 $OVAL

_amixer=$(amixer -c 0 -- sget Master 2>/dev/null)
ACTUAL_VOL="$(echo $_amixer | grep -E -o '[[:digit:]]+%')"
pkill -u $USER aosd_cat
echo "VOLUME $ACTUAL_VOL" | aosd_cat -n "Sans 12 bold" -p 7 -o 3000 -R gray -f 0
