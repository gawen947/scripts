#!/bin/sh
# Copyright (c) 2014 David Hauweele <david@hauweele.net>

if [ $# != 1 ]
then
  echo "usage: $0 <timeout in seconds>"
  exit 1
fi

timeout="$1"

t=0
while true
do
  sleep 1
  t=$(rpnc $t 1 +)
  pct=$(rpnc 100 "$timeout" / $t .)
  echo "$pct"
done | zenity --progress --title "$0" --text "This system will halt..." --auto-close

if [ "$?" = 1 ]
then
  echo "cancel halt."
else
  if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]
  then
    echo "halt using DBus..."
    dbus-send --system --print-reply --dest="org.freedesktop.ConsoleKit" /org/freedesktop/ConsoleKit/Manager org.freedesktop.ConsoleKit.Manager.Stop
  else
    echo "halt..."
    /sbin/halt
fi
