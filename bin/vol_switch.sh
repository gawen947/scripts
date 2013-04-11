#!/bin/sh
# Copyright (c) 2011 David Hauweele <david@hauweele.net>

A=$(pacmd dump | grep "set-sink-mute alsa_output.pci-0000_00_1b.0.analog-stereo" | cut -d " " -f 3)
if [ $A = "no" ]
then
    pactl set-sink-mute 0 yes
    pkill -u $USER aosd_cat
    echo "SPEAKERS OFF" | aosd_cat -n "Sans 20 bold" -p 7 -o 3000 -R red -f 0
else
    pactl set-sink-mute 0 no
    pkill -u $USER aosd_cat
    echo "SPEAKERS ON " | aosd_cat -n "Sans 20 bold" -p 7 -o 3000 -R yellow -f 0
fi
